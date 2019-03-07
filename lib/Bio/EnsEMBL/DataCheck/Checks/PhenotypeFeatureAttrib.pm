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

package Bio::EnsEMBL::DataCheck::Checks::PhenotypeFeatureAttrib;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'PhenotypeFeatureAttrib',
  DESCRIPTION    => 'Imported phenotype_feature_attrib value is meaningful and well-formed',
  DATACHECK_TYPE => 'advisory',
  GROUPS         => ['variation_import'],
  DB_TYPES       => ['variation'],
  TABLES         => ['phenotype_feature_attrib']
};

sub tests {
  my ($self) = @_;

  my $desc_non_term = 'Meaningful phenotype_feature_attrib value';
  my $diag_non_term = 'phenotype_feature_attrib value is not useful';
  my $sql_non_term = qq/
      SELECT phenotype_feature_id
      FROM phenotype_feature_attrib
      WHERE lower(value) in ("none", "not specified", "not in omim", "variant of unknown significance", "?", ".")
  /;
  is_rows_zero($self->dba, $sql_non_term, $desc_non_term, $diag_non_term);  

  my $desc_ascii = 'ASCII chars printable in value';
  my $diag_ascii = "value with unsupported ASCII chars";
  my $sql_ascii = qq/
      SELECT phenotype_feature_id
      FROM phenotype_feature_attrib
      WHERE value REGEXP '[^ -;=\?-~]'
      OR LEFT(value, 1) REGEXP '[^A-Za-z0-9]'
  /;
  is_rows_zero($self->dba, $sql_ascii, $desc_ascii, $diag_ascii); 

}

1;

