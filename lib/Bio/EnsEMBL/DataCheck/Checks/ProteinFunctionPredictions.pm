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

package Bio::EnsEMBL::DataCheck::Checks::ProteinFunctionPredictions;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ProteinFunctionPredictions',
  DESCRIPTION => 'Protein function predictions are present and correct',
  GROUPS      => ['variation'],
  DB_TYPES    => ['variation'],
  TABLES      => ['protein_function_predictions']
};

sub skip_tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor('MetaContainer');
  my $vcf = list_value_by_key('variation_source.vcf')->[0] || 0;

  if ($vcf) {
    return( 1, "Protein function predictions are not expected for species whose variation source is VCF." );
  }
}

sub tests {
  my ($self) = @_;
  my $desc = 'prediction_matrix is NOT NULL or empty';
  my $sql  = qq/
    SELECT COUNT(*) FROM protein_function_predictions
    WHERE prediction_matrix IS NULL OR prediction_matrix = ''
  /;
  is_rows_zero($self->dba, $sql, $desc);

}

1;
