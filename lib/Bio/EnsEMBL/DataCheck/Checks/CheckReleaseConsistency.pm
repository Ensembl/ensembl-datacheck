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

package Bio::EnsEMBL::DataCheck::Checks::CheckReleaseConsistency;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckReleaseConsistency',
  DESCRIPTION    => 'Check for consistency between retired genomes and species_sets',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_master', 'compara_syntenies'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['genome_db', 'method_link_species_set', 'species_set_header']
};

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;
  
  my $desc_1 = "Both %s and %s has been released";
  my $c_sql_1 = "t1.first_release IS NULL AND t2.first_release IS NOT NULL";
  my $desc_2 = "Both the %s and %s are current";
  my $c_sql_2 = "t1.last_release IS NOT NULL AND t2.first_release IS NOT NULL AND t2.last_release IS NULL";
  my $desc_3 = "The %s has not been released before the %s";
  my $c_sql_3 = "t1.first_release IS NOT NULL AND t2.first_release IS NOT NULL AND t2.first_release < t1.first_release";
  my $desc_4 = "The %s has not been retired before the %s";
  my $c_sql_4 = "t1.last_release IS NOT NULL AND t2.last_release IS NOT NULL AND t2.last_release > t1.last_release"; 
    
  my %sql_conditions = (
    $c_sql_1 => $desc_1,
    $c_sql_2 => $desc_2,
    $c_sql_3 => $desc_3,
    $c_sql_4 => $desc_4
  );
  
  while ( my ( $condition, $desc ) = each %sql_conditions ) {
    my $sql_1 = qq/
    SELECT COUNT(*) 
      FROM genome_db t1 
        JOIN species_set 
          USING (genome_db_id) 
        JOIN species_set_header t2 
          USING (species_set_id)
    WHERE $condition
    /;
    my $detail_desc = sprintf($desc, "genome_db", "species_set") . " for rows in genome_db, species_set and species_set_header";
    is_rows_zero($dbc, $sql_1, $detail_desc);
    
    my $sql_2 = qq/
    SELECT COUNT(*) 
      FROM genome_db t1 
        JOIN species_set 
          USING (genome_db_id) 
        JOIN method_link_species_set t2 
          USING (species_set_id)
    WHERE $condition
    /;
    $detail_desc = sprintf($desc, "genome_db", "method_link_species_set") . " for rows in genome_db, species_set and method_link_species_set";
    is_rows_zero($dbc, $sql_2, $detail_desc);
    
    my $sql_3 = qq/
    SELECT COUNT(*)
      FROM species_set_header t1 
        JOIN method_link_species_set t2 
          USING (species_set_id)
    WHERE $condition
    /;
    $detail_desc = sprintf($desc, "species_set_header", "method_link_species_set") . " for rows in method_link_species_set and species_set_header";
    is_rows_zero($dbc, $sql_3, $detail_desc);
    
  }
}

1;

