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
  # With DataCheck displaying some examples and SQL
  my $desc_1 = 'Variation features are unique';
  my $diag_1 = 'Duplicate';
  my $sql_1  = qq/
    SELECT variation_id, seq_region_id, seq_region_start, 
           seq_region_end, count(variation_feature_id)
    FROM variation_feature
    GROUP BY variation_id, seq_region_id, seq_region_start, seq_region_end
    HAVING count(variation_feature_id) > 1
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  # The MAF is also checked in Variation table
  # TODO combine the MAF checks
  my $desc_2 = 'VariationFeatures minor_allele_freq <= 0.5';
  my $sql_2  = qq/
    SELECT COUNT(*) 
    FROM variation
    WHERE minor_allele_freq > 0.5
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2);
}

1;
