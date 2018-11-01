=head1 LICENSE

Copyright [2018] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::RepeatFeatureCoords;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'RepeatFeatureCoords',
  DESCRIPTION => 'Check that repeat feature coordinates are sensible',
  GROUPS      => ['core_handover'],
  DB_TYPES    => ['core']
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;

  my $desc_1 = 'Repeat start >= repeat end';
  my $sql_1  = qq/
    SELECT COUNT(*) FROM
      repeat_feature INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id)
    WHERE
      repeat_start > repeat_end AND
      coord_system.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);

  my $desc_2 = 'Repeat start and end > 0';
  my $sql_2  = qq/
    SELECT COUNT(*) FROM
      repeat_feature INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id)
    WHERE
      repeat_start < 1 OR repeat_end < 1 AND
      coord_system.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2);
}

1;
