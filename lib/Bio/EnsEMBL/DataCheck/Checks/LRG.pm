=head1 LICENSE

# Copyright [2018] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

=cut

package Bio::EnsEMBL::DataCheck::Checks::LRG;

use warnings;
use strict;
use feature 'say';

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'LRG',
  DESCRIPTION => 'Check that LRG features and seq_regions are correctly associated.',
  DB_TYPES    => ['core'],
  TABLES      => ['coord_system', 'gene',  'seq_region', 'transcript'],
  GROUPS      => ['handover'],
};

sub skip_tests {
  my ($self) = @_;

  my $dba = $self->dba;
  my $helper = $dba->dbc->sql_helper;

  my $lrg_sql = q/
    SELECT COUNT(*) FROM
      coord_system cs INNER JOIN
      seq_region sr USING (coord_system_id)
    WHERE cs.name = 'lrg'
  /;

  my $lrg_regions = $helper->execute_single_result(-SQL => $lrg_sql);

  if (!$lrg_regions) {
    return (1, 'No LRG regions.');
  }
}

sub tests {
  my ($self) = @_;
  my $helper = $self->dba->dbc->sql_helper;

  $self->lrg_annotations($helper, 'gene');
  $self->lrg_annotations($helper, 'transcript');
}

sub lrg_annotations {
  my ($self, $helper, $feature) = @_;

  my $desc_1 = "Coordinate system with LRG features is named 'lrg'";
  my $sql_1  = qq/
    SELECT DISTINCT cs.name FROM
      coord_system cs INNER JOIN
      seq_region sr USING (coord_system_id) INNER JOIN
      $feature f USING (seq_region_id)
    WHERE f.biotype LIKE 'LRG%' AND cs.name <> 'lrg'
  /;
  my $coord_systems = $helper->execute_simple(-SQL => $sql_1);
  is(@$coord_systems, 0, $desc_1);

  foreach (@$coord_systems) {
    diag("Coordinate system $_ has LRG features");
  }

  my $desc_2 = "Features on 'lrg' coordinate system have 'LRG%' biotype";
  my $sql_2  = qq/
    SELECT DISTINCT f.biotype FROM
      coord_system cs INNER JOIN
      seq_region sr USING (coord_system_id) INNER JOIN
      $feature f USING (seq_region_id)
    WHERE f.biotype NOT LIKE 'LRG%' AND cs.name = 'lrg'
  /;
  my $biotypes = $helper->execute_simple(-SQL => $sql_2);
  is(@$biotypes, 0, $desc_2);

  foreach (@$biotypes) {
    diag("Features with Non-LRG biotype ($_) on 'lrg' coordinate system");
  }
}

1;
