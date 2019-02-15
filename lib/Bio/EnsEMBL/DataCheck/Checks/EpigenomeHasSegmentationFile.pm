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

package Bio::EnsEMBL::DataCheck::Checks::EpigenomeHasSegmentationFile;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'EpigenomeHasSegmentationFile',
  DESCRIPTION => 'All epigenomes in the current regulatory build have a segmentation file',
  GROUPS      => ['funcgen', 'regulatory_build'],
  DB_TYPES    => ['funcgen'],
  TABLES      => ['regulatory_build','regulatory_build_epigenome','epigenome'],
};

sub skip_tests {
  my ($self) = @_;

  my $sql = q/
    SELECT COUNT(name) FROM regulatory_build 
    WHERE is_current=1
  /;

  if (! sql_count($self->dba, $sql) ) {
    return (1, 'The database has no regulatory build');
  }
}

sub tests {
  my ($self) = @_;
  my $desc = "All the epigenomes of the current regulatory build have a segmentation file";
  my $diag = "Segmentation file missing";
  my $sql = q/
    SELECT e.epigenome_id FROM
      regulatory_build rb INNER JOIN
      regulatory_build_epigenome rbe ON rb.regulatory_build_id = rbe.regulatory_build_id INNER JOIN
      epigenome e ON rbe.epigenome_id = e.epigenome_id LEFT OUTER JOIN
      segmentation_file sf ON e.epigenome_id = sf.epigenome_id
    WHERE rb.is_current = 1 AND sf.epigenome_id is null
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;

