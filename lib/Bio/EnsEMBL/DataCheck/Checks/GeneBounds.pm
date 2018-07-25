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

package Bio::EnsEMBL::DataCheck::Checks::GeneBounds;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'GeneBounds',
  DESCRIPTION => 'Ensure that genes are within the bounds of their seq_region',
  GROUPS      => ['core_handover'],
  DB_TYPES    => ['core', 'otherfeatures'],
  TABLES      => ['coord_system', 'gene', 'seq_region', 'transcript']
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;

  # We need to use SQL rather than the API, because the API will
  # not necessarily return genes which are beyond slice bounds,
  # so we would miss any problems.

  my $desc_1 = 'Genes within seq_region bounds';
  my $diag_1 = 'Out-of-bounds gene';
  my $sql_1  = qq/
    SELECT stable_id FROM
      gene INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id)
    WHERE
      gene.seq_region_end > seq_region.length AND
      coord_system.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  my $desc_2 = 'Transcripts within seq_region bounds';
  my $diag_2 = 'Out-of-bounds transcript';
  my $sql_2  = qq/
    SELECT stable_id FROM
      transcript INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id)
    WHERE
      transcript.seq_region_end > seq_region.length AND
      coord_system.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);
}

1;

