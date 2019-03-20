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

package Bio::EnsEMBL::DataCheck::Checks::Population;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'Population',
  DESCRIPTION => 'Population data is consistent',
  GROUPS      => ['variation_import'], 
  DB_TYPES    => ['variation'],
  TABLES      => ['population']
};

sub tests {
  my ($self) = @_;

  my $desc_length = 'Population size'; 
  my $diag_length = 'Population has no stored size'; 
  my $sql_length = qq/
      SELECT p.population_id
      FROM population p
      INNER JOIN sample_population sp USING(population_id)
      WHERE p.size is NULL
  /;
  is_rows_zero($self->dba, $sql_length, $desc_length, $diag_length); 

  my $species = $self->species; 

  if($species =~ /homo_sapiens|mus_musculus/){ 
    my $desc = 'No populations have freqs_from_gts set'; 
    my $sql = qq/
        SELECT population_id
        FROM population
        WHERE freqs_from_gts = 1
    /; 
    is_rows_nonzero($self->dba, $sql, $desc); 
  } 

  if($species =~ /homo_sapiens/){
    my $desc_display = 'Number of display groups set for current population'; 
    my $sql_display = qq/
        SELECT COUNT(DISTINCT display_group_id)
        FROM population
    /; 
    cmp_rows($self->dba, $sql_display, '==', 3, $desc_display); 
  }

}

1;

