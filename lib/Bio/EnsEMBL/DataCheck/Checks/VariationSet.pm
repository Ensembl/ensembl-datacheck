=head1 LICENSE

Copyright [2018-2020] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::VariationSet;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'VariationSet',
  DESCRIPTION => 'Variation set is not missing name/description and contains valid id',
  GROUPS      => ['variation_import'], 
  DB_TYPES    => ['variation'],
  TABLES      => ['variation_set']
};

sub tests {
  my ($self) = @_;

  my $desc_name = 'Variation set has a name';
  my $diag_name = 'Variation set name is missing';
  has_data($self->dba, 'variation_set', 'name', 'variation_set_id', $desc_name, $diag_name);

  my $desc_description = 'Variation set has a description';
  my $diag_description = 'Variation set description is missing';
  has_data($self->dba, 'variation_set', 'description', 'variation_set_id', $desc_description, $diag_description);

  my $desc_id = 'Variation set id is valid';
  my $diag_id = 'Variation set id is not valid to fit into variation_set_id column in variation_feature table';
  my $sql_id = q/
      SELECT COUNT(*)
      FROM variation_set
      WHERE variation_set_id > 64
  /;
  is_rows_zero($self->dba, $sql_id, $desc_id, $diag_id);

}

1;

