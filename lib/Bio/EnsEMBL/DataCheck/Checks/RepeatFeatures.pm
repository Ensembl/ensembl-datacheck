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

package Bio::EnsEMBL::DataCheck::Checks::RepeatFeatures;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'RepeatFeatures',
  DESCRIPTION => 'Repeat feature coordinates are present and correct',
  GROUPS      => ['annotation', 'core'],
  DB_TYPES    => ['core'],
  TABLES      => ['analysis', 'coord_system', 'repeat_feature', 'seq_region'],
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;

  SKIP: {
    if ($self->dba->is_multispecies) {
      skip "Repeat features not mandatory for species in collection dbs", 1;
    }

    # Don't need to worry about species_id, because we don't do this
    # query for collection dbs...
    my @logic_names = ('dust', 'trf');
    foreach my $logic_name (@logic_names) {
      my $desc_1 = "Repeat features exist ($logic_name)";
      my $sql_1  = qq/
        SELECT COUNT(*) FROM
          repeat_feature INNER JOIN
          analysis USING (analysis_id)
        WHERE
          logic_name = '$logic_name'
      /;
      is_rows_nonzero($self->dba, $sql_1, $desc_1);
    }

    my $desc_2 = 'Repeat features exist (repeatmask)';
    my $sql_2  = qq/
      SELECT COUNT(*) FROM
        repeat_feature INNER JOIN
        analysis USING (analysis_id)
      WHERE
        logic_name LIKE 'repeatmask%'
    /;
    is_rows_nonzero($self->dba, $sql_2, $desc_2);
  }

  my $desc_3 = 'Repeat start <= repeat end';
  my $sql_3  = qq/
    SELECT COUNT(*) FROM
      repeat_feature INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id)
    WHERE
      repeat_start > repeat_end AND
      coord_system.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_3, $desc_3);

  my $desc_4 = 'Repeat start > 0';
  my $sql_4  = qq/
    SELECT COUNT(*) FROM
      repeat_feature INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id)
    WHERE
      repeat_start < 1 AND
      coord_system.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_4, $desc_4);
}

1;
