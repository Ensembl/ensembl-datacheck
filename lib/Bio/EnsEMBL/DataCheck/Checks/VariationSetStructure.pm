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

package Bio::EnsEMBL::DataCheck::Checks::VariationSetStructure;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'VariationSetStructure',
  DESCRIPTION => 'Variation set only has one super set attached to it',
  GROUPS      => ['variation_import'],
  DB_TYPES    => ['variation'],
  TABLES      => ['variation_set_structure']
};

sub tests {
  my ($self) = @_;

  my $desc = 'Variation set has one super set attached to it';
  my $diag = 'Variation set has more than one super set attached to it';
  my $sql = q/
      SELECT variation_set_sub
      FROM variation_set_structure
      GROUP BY (variation_set_sub)
      HAVING COUNT(*) > 1
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);

}

1;

