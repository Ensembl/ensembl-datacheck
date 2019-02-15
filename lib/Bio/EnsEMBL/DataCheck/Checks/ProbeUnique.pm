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

package Bio::EnsEMBL::DataCheck::Checks::ProbeUnique;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ProbeUnique',
  DESCRIPTION => 'Probe IDs and mappings are unique',
  GROUPS      => ['funcgen', 'probe_mapping'],
  DB_TYPES    => ['funcgen'],
  TABLES      => ['array', 'array_chip', 'probe', 'probe_set_transcript', 'probe_transcript']
};

sub tests {
  my ($self) = @_;

  my $diag = 'Duplicate';

  # This doesn't seem necessary, a table constraint enforces this,
  # but it was a current healthcheck at time of writing...
  my $desc_1 = 'Probe IDs are unique';
  my $sql_1  = q/
    SELECT probe_id FROM probe
    GROUP BY probe_id
    HAVING COUNT(*) > 1
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1, $diag);

  my $desc_2 = 'Probe-transcript mappings are unique';
  my $sql_2  = q/
    SELECT probe_id, stable_id FROM probe_transcript
    GROUP BY probe_id, stable_id
    HAVING COUNT(*) > 1
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2, $diag);

  my $desc_3 = 'Probeset-transcript mappings are unique';
  my $sql_3  = q/
    SELECT probe_set_id, stable_id FROM probe_set_transcript
    GROUP BY probe_set_id, stable_id
    HAVING COUNT(*) > 1
  /;
  is_rows_zero($self->dba, $sql_3, $desc_3, $diag);

  my $desc_4 = 'Arrays have unique probes';
  my $sql_4  = q/
    SELECT DISTINCT array.name FROM 
      array INNER JOIN
      array_chip USING (array_id) INNER JOIN
      probe USING (array_chip_id)
    WHERE array.is_probeset_array = false
    GROUP BY
      array.name, probe.name
    having COUNT(distinct probe.probe_id) > 1
  /;
  is_rows_zero($self->dba, $sql_4, $desc_4, $diag);

  my $desc_5 = 'Arrays have unique probesets';
  my $sql_5  = q/
    SELECT DISTINCT array.name FROM
      array INNER JOIN
      array_chip USING (array_id) INNER JOIN
      probe USING (array_chip_id)
    WHERE array.is_probeset_array = true
    GROUP BY
      array.name, probe.name, probe.probe_set_id
    HAVING COUNT(distinct probe.probe_id) > 1
  /;
  is_rows_zero($self->dba, $sql_5, $desc_5, $diag);
}

1;
