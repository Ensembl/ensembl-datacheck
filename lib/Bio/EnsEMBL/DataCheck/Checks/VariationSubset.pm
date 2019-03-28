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

package Bio::EnsEMBL::DataCheck::Checks::VariationSubset;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'VariationSubset',
  DESCRIPTION => 'Variation set is not a subset of itself',
  GROUPS      => ['variation_import'],
  DB_TYPES    => ['variation'],
  TABLES      => ['variation_set','variation_set_structure']
};

sub tests {
  my ($self) = @_;

  my $desc = 'Variation set is not a subset of itself';
  my $diag = 'Variation set is a subset of itself';
  my $sql = qq/
      SELECT DISTINCT v.name
      FROM  variation_set v
      JOIN variation_set_structure vs
      ON (vs.variation_set_sub = vs.variation_set_super
      AND v.variation_set_id = vs.variation_set_super)
  /;
  my $result = is_rows_zero($self->dba, $sql, $desc, $diag);

  SKIP: {
  
    skip 'Not running test for variations in superset', 1 unless $result == 1;
 
    my $desc_2 = 'Variations that are in a set are not present in the subset';
    my $sql_2 = qq/
        SELECT DISTINCT vs1.variation_set_id, vs2.variation_set_id
        FROM variation_set_variation vs1
        JOIN variation_set_variation vs2
        ON (vs2.variation_id = vs1.variation_id
        AND vs2.variation_set_id > vs1.variation_set_id) limit 100
    /;
    my $data = get_data($self->dba, $sql_2);
    
    my $test_result;
    foreach my $element (@$data){
      my $set1 = @$element[0];
      my $set2 = @$element[1]; 

      my $data_set1 = $self->get_set($set1);
      my $related = $set2 ~~ $data_set1;
      
      if(!$related){
        my $data_set2 = $self->get_set($set2);
        $related = $set1 ~~ $data_set2;
      }
      if($related){
        $test_result = 1; 
        diag("The variation set ($set1) contains variants that are present in the subset ($set2). Preferably only subset ($set2) should contain those variants"); 
      }
    }
    ok(!defined($test_result), $desc_2);
  }

}

sub get_set {
  my ($self, $value) = @_;

  my $sql = qq/
        SELECT variation_set_sub
        FROM variation_set_structure
        WHERE variation_set_super = $value
      /;
  my $data = get_data($self->dba, $sql);

  return $data;
}

1;

