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

package Bio::EnsEMBL::DataCheck::Checks::CompareProteinCodingGeneNames;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw(same_assembly same_geneset);

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareProteinCodingGeneNames',
  DESCRIPTION    => 'Compare Protein Coding Gene Name counts between two databases.',
  GROUPS         => ['xref_mapping'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['gene', 'coord_system', 'seq_region']
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

  my $threshold = 0.9;
  my $min_count = 5;

  my $desc = "Consistent protein coding gene name counts between ".
             $self->dba->dbc->dbname.
             ' (species_id '.$self->dba->species_id.') and '.
             $old_dba->dbc->dbname.
             ' (species_id '.$old_dba->species_id.')';
  my $sql  = qq/
    SELECT count(g.gene_id) FROM 
      gene g INNER JOIN 
      xref x ON g.display_xref_id = x.xref_id INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN 
      coord_system USING (coord_system_id)
    WHERE
      g.display_xref_id IS NOT NULL AND 
      g.biotype='protein_coding' AND 
      x.info_type!='PROJECTION'
  /;

  row_totals($self->dba, $old_dba, $sql, undef, $threshold, $desc, $min_count);
}

1;
