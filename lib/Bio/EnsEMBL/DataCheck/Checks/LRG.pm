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

package Bio::EnsEMBL::DataCheck::Checks::LRG;

use warnings;
use strict;
use feature 'say';

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'LRG',
  DESCRIPTION => 'LRG features and seq_regions are correctly configured',
  GROUPS      => ['core', 'xref'],
  DB_TYPES    => ['core'],
  TABLES      => ['coord_system', 'gene',  'seq_region', 'transcript'],
  PER_DB      => 1,
};

sub skip_tests {
  my ($self) = @_;

  my $sql = q/
    SELECT COUNT(*) FROM
      coord_system cs INNER JOIN
      seq_region sr USING (coord_system_id)
    WHERE cs.name = 'lrg'
  /;

  if (! sql_count($self->dba, $sql) ) {
    return (1, 'No LRG regions.');
  }
}

sub tests {
  my ($self) = @_;

  $self->lrg_annotations('gene');
  $self->lrg_annotations('transcript');
}

sub lrg_annotations {
  my ($self, $feature) = @_;

  my $desc_1 = "Coordinate system with LRG $feature features is named 'lrg'";
  my $diag_1 = "Non-LRG coordinate system has LRG $feature features";
  my $sql_1  = qq/
    SELECT DISTINCT cs.name FROM
      coord_system cs INNER JOIN
      seq_region sr USING (coord_system_id) INNER JOIN
      $feature f USING (seq_region_id)
    WHERE f.biotype LIKE 'LRG%' AND cs.name <> 'lrg'
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  my $desc_2 = "$feature features on 'lrg' coordinate system have 'LRG%' biotype";
  my $diag_2 = "$feature features with non-LRG biotype on 'lrg' coordinate system";
  my $sql_2  = qq/
    SELECT DISTINCT f.biotype FROM
      coord_system cs INNER JOIN
      seq_region sr USING (coord_system_id) INNER JOIN
      $feature f USING (seq_region_id)
    WHERE f.biotype NOT LIKE 'LRG%' AND cs.name = 'lrg'
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);
}

1;
