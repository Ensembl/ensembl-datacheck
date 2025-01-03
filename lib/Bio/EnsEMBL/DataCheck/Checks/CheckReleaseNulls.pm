=head1 LICENSE

Copyright [2018-2025] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CheckReleaseNulls;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckReleaseNulls',
  DESCRIPTION    => 'For release DB the last_release must be NULL but cannot have a NULL first_release',
  GROUPS         => ['compara', 'compara_master', 'compara_syntenies', 'compara_references'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['genome_db', 'method_link_species_set', 'species_set_header']
};

sub tests {
  my ($self) = @_;
  my $db_release = $self->dba->get_MetaContainerAdaptor->schema_version;
  my $dbc = $self->dba->dbc;
  my $db_name = $dbc->dbname;
  
  my @tables = qw(genome_db method_link_species_set species_set_header);
  
  foreach my $table (@tables) {
    
    if ( $db_name =~ /master/i or $db_name =~ /references/i ) {
      # In the master database, last_release cannot be set in the future (incl. the current release)
      my $sql_1 = qq/
        SELECT COUNT(*) 
          FROM $table 
        WHERE last_release IS NOT NULL 
          AND last_release >= $db_release
      /;
      my $desc_1 = "For $table all the last_release fields are realistically in the present or past";
      is_rows_zero($dbc, $sql_1, $desc_1);
      
    }
    else {
      # last_release should be NULL in the release database
      my $sql_2 = qq/
        SELECT COUNT(*) 
          FROM $table 
        WHERE last_release IS NOT NULL 
      /;
      my $desc_2 = "For $table the last_release is NULL";
      is_rows_zero($dbc, $sql_2, $desc_2);
      # NULL + NULL is only allowed in the master database
      my $sql_3 = qq/
        SELECT COUNT(*) 
          FROM $table 
        WHERE first_release IS NULL 
          AND last_release IS NULL
      /;
      my $desc_3 = "For $table first_release is NOT NULL whilst last_release is NOT NULL";
      is_rows_zero($dbc, $sql_3, $desc_3);
      
    }
    
  }

}

1;

