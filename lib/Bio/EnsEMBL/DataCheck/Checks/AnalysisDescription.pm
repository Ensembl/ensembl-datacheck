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

package Bio::EnsEMBL::DataCheck::Checks::AnalysisDescription;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'AnalysisDescription',
  DESCRIPTION => 'Gene analyses have descriptions',
  GROUPS      => ['core', 'corelike', 'geneset'],
  DB_TYPES    => ['core', 'otherfeatures'],
  TABLES      => ['analysis', 'analysis_description', 'gene', 'prediction_transcript', 'transcript']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my @tables = qw/gene transcript prediction_transcript/;
  foreach my $table (@tables) {
    my $desc = "Analysis descriptions for all ${table}s";
    my $sql  = qq/
      SELECT COUNT(*) FROM
        $table LEFT OUTER JOIN
        analysis_description ad USING (analysis_id) INNER JOIN
        seq_region USING (seq_region_id) INNER JOIN
        coord_system USING (coord_system_id)
      WHERE
        ad.analysis_id IS NULL AND
        species_id = $species_id
    /;
    is_rows_zero($self->dba, $sql, $desc);
  }
}

1;
