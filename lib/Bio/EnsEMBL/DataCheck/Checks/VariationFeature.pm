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

package Bio::EnsEMBL::DataCheck::Checks::VariationFeature;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'VariationFeature',
  DESCRIPTION => 'VariationFeature table data is present and correct',
  GROUPS      => ['variation_tables'],
  DB_TYPES    => ['variation'],
  TABLES      => ['variation_feature']
};

sub tests {
  my ($self) = @_;
  
  # In HC the check for duplicates was a COUNT
  # The datacheck has used COUNT as this was quicker
  # than using a GROUP BY and displaying example duplicates
  my $desc_1 = 'Variation features are unique';
  my $sql_1 = qq/
   SELECT COUNT(DISTINCT vf1.variation_id)
   FROM variation_feature vf1 JOIN variation_feature vf2
    ON (vf2.variation_id = vf1.variation_id
        AND vf2.variation_feature_id > vf1.variation_feature_id
        AND vf2.seq_region_id = vf1.seq_region_id
        AND vf2.seq_region_start = vf1.seq_region_start
        AND vf2.seq_region_end = vf1.seq_region_end)
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);

  # The MAF is also checked in Variation table
  # TODO combine the MAF checks
  my $desc_2 = 'VariationFeatures minor_allele_freq <= 0.5';
  my $sql_2  = qq/
    SELECT COUNT(*) 
    FROM variation_feature
    WHERE minor_allele_freq > 0.5
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2);
}

1;
