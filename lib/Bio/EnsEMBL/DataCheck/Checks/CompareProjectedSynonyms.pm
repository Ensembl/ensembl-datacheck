=head1 LICENSE

Copyright [2018-2022] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CompareProjectedSynonyms;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareProjectedSynonyms',
  DESCRIPTION    => 'Compare Projected Synonyms counts between two databases, categorised by db_name coming from the external_db',
  GROUPS         => ['compare_core', 'xref', 'xref_name_projection'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['xref','external_db','external_synonym','object_xref']
};

sub tests {
  my ($self) = @_;

  SKIP: {
    my $old_dba = $self->get_old_dba();

    skip 'No old version of database', 1 unless defined $old_dba;

    $self->projected_synonyms_counts($old_dba);
  }
}

sub projected_synonyms_counts {
  my ($self, $old_dba) = @_;

  my $threshold = 0.66;

  my $desc = "Checking Projected Synonyms between ".
             $self->dba->dbc->dbname.
             ' (species_id '.$self->dba->species_id.') and '.
             $old_dba->dbc->dbname.
             ' (species_id '.$old_dba->species_id.')';
  my $sql  = qq/
      SELECT e.db_name, COUNT(*) FROM 
        xref x INNER JOIN
        external_db e USING (external_db_id) INNER JOIN
        external_synonym es USING (xref_id) INNER JOIN        
        object_xref ox USING (xref_id)  INNER JOIN
        gene g ON ox.ensembl_id = g.gene_id INNER JOIN 
        seq_region sr USING (seq_region_id) INNER JOIN
        coord_system cs USING (coord_system_id)
      WHERE 
        x.info_type = 'PROJECTION' AND
        ox.ensembl_object_type = 'Gene' AND
        cs.species_id = %d
      GROUP BY e.db_name 
  /;
  my $sql1 = sprintf($sql, $self->dba->species_id);
  my $sql2 = sprintf($sql, $old_dba->species_id);
  row_subtotals($self->dba, $old_dba, $sql1, $sql2, $threshold, $desc);
}
1;
