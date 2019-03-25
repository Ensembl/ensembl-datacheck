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

package Bio::EnsEMBL::DataCheck::Checks::VariationSetAttrib;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'VariationSetAttrib',
  DESCRIPTION => 'The short name attrib for variation_set_id exists and is defined in attrib table',
  GROUPS      => ['variation_import'], 
  DB_TYPES    => ['variation'],
  TABLES      => ['variation_set', 'attrib']
};

sub tests {
  my ($self) = @_;

  my $desc = 'The short name attrib for variation_set_id exists and is defined in attrib table';
  my $diag = 'The short name attrib for variation_set_id is not defined in attrib table';
  my $sql = q/
      SELECT v.variation_set_id
      FROM variation_set v
      LEFT JOIN attrib a
      ON (v.short_name_attrib_id = a.attrib_id)
      WHERE v.variation_set_id IS NOT NULL
      AND a.value IS NULL
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);

}

1;

