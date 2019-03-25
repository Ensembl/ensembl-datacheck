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

package Bio::EnsEMBL::DataCheck::Checks::VariationFeatureAlleles;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'VariationFeatureAlleles',
  DESCRIPTION => 'VariationFeature has alleles',
  GROUPS      => ['variation_tables'],
  DB_TYPES    => ['variation'],
  TABLES      => ['variation_feature']
};

sub tests {
  my ($self) = @_;
  
  my $desc_1 = 'Variation feature is not missing alleles';
  my $sql_1  = qq(
    SELECT COUNT(variation_feature_id) 
    FROM variation_feature 
    WHERE allele_string LIKE '%/' 
       OR allele_string LIKE '%//%'
       OR allele_string LIKE '/%'
  );
  is_rows_zero($self->dba, $sql_1, $desc_1);
}

1;
