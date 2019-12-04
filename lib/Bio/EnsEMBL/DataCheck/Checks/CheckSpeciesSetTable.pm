=head1 LICENSE

Copyright [2018-2019] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CheckSpeciesSetTable;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckSpeciesSetTable',
  DESCRIPTION    => 'Check species_set_tags have no orphans and species_sets are unique',
  GROUPS         => ['compara'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['species_set', 'species_set_tag']
};

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;
  
  fk($dbc, "species_set_tag", "species_set_id", "species_set_header", "species_set_id");
  
  my $sql = q/
    SELECT gdb_ids, count(*) num, GROUP_CONCAT(species_set_id ORDER BY species_set_id) AS species_set_ids 
    FROM (
      SELECT species_set_id, GROUP_CONCAT(genome_db_id ORDER BY genome_db_id) AS gdb_ids 
        FROM species_set GROUP BY species_set_id
   	) t1 
    GROUP BY gdb_ids 
    HAVING COUNT(*)>1
  /;
  
  my $desc = "All of the species_set entries are unique";
  is_rows_zero($dbc, $sql, $desc);
  
}

1;

