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

package Bio::EnsEMBL::DataCheck::Checks::StructuralVariationFeature;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'StructuralVariationFeature',
  DESCRIPTION => 'StructuralVariationFeature table data is present and correct',
  GROUPS      => ['variation'],
  DB_TYPES    => ['variation'],
  TABLES      => ['structural_variation_feature']
};

sub tests {
  my ($self) = @_;
  
  # In the HC the check for duplicates was a COUNT on a self join.
  # The datacheck has used a GROUP BY and displays example 
  # duplicates on failure.
  my $desc = 'Structural variation features are unique';
  my $sql = qq/
    SELECT structural_variation_id, seq_region_id, seq_region_start, 
           seq_region_end, seq_region_strand, COUNT(structural_variation_id)
    FROM structural_variation_feature
    GROUP BY structural_variation_id, seq_region_id, seq_region_start, 
          seq_region_end, seq_region_strand
    HAVING COUNT(structural_variation_id) > 1
  /;
  is_rows_zero($self->dba, $sql, $desc);
}

1;
