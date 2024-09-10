=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the 'License');
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an 'AS IS' BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Bio::EnsEMBL::DataCheck::Checks::CompareGeneNames;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw(same_assembly same_geneset);

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareGeneNames',
  DESCRIPTION    => 'Compare Gene Name counts between two databases, categorised by external_db.',
  GROUPS         => ['xref_mapping'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['xref', 'gene', 'object_xref', 'seq_region', 'coord_system', 'external_db']
};

sub tests {
  my ($self) = @_;

  SKIP: {
    my $old_dba = $self->get_old_dba();

    skip 'No old version of database', 1 unless defined $old_dba;

    $self->gene_name_counts($old_dba);
  }
}

sub gene_name_counts {
  my ($self, $old_dba) = @_;

  my $threshold = 0.33;

  my $desc = "Consistent number of genes with names between ".
             $self->dba->dbc->dbname.
             ' (species_id '.$self->dba->species_id.') and '.
             $old_dba->dbc->dbname.
             ' (species_id '.$old_dba->species_id.')';

  my $sql = qq/
    SELECT count(gene_id) FROM gene 
    WHERE display_xref_id IS NOT NULL
  /;

  my $sql1 = sprintf($sql);
  my $sql2 = sprintf($sql);

  row_totals($self->dba, $old_dba, $sql1, $sql2, $threshold, $desc);

  $desc = "Consistent gene name counts between ".
             $self->dba->dbc->dbname.
             ' (species_id '.$self->dba->species_id.') and '.
             $old_dba->dbc->dbname.
             ' (species_id '.$old_dba->species_id.')';
  $sql  = qq/
    SELECT db_name, COUNT(*) FROM
      gene g INNER JOIN 
      xref x ON g.display_xref_id = x.xref_id INNER JOIN 
      external_db USING (external_db_id) INNER JOIN 
      seq_region USING (seq_region_id) INNER JOIN 
      coord_system USING (coord_system_id) INNER JOIN
      object_xref USING (xref_id)
    WHERE
      db_name <> 'GO' AND
      info_type <> 'PROJECTION' AND
      ensembl_object_type = 'Gene' AND
      ensembl_id = gene_id AND
      species_id = %d
    GROUP BY db_name
  /;

  $sql1 = sprintf($sql, $self->dba->species_id);
  $sql2 = sprintf($sql, $old_dba->species_id);
  row_subtotals($self->dba, $old_dba, $sql1, $sql2, $threshold, $desc);
}
1;
