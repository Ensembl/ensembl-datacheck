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

package Bio::EnsEMBL::DataCheck::Checks::FuncgenAnalysisDescription;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'FuncgenAnalysisDescription',
  DESCRIPTION => 'Probe features and feature sets have descriptions and are displayable',
  GROUPS      => ['funcgen'],
  DB_TYPES    => ['funcgen'],
  TABLES      => ['analysis', 'analysis_description', 'feature_set', 'probe_feature']
};

sub tests {
  my ($self) = @_;

  my @tables = qw/feature_set probe_feature/;
  foreach my $table (@tables) {
    my $desc_1 = "Analysis descriptions for all ${table}s";
    my $sql_1  = qq/
      SELECT COUNT(*) FROM
        $table LEFT OUTER JOIN
        analysis_description ad USING (analysis_id)
      WHERE
        ad.analysis_id IS NULL
    /;
    is_rows_zero($self->dba, $sql_1, $desc_1);

    my $desc_2 = "Displayable analysis for all ${table}s";
    my $sql_2  = qq/
      SELECT COUNT(*) FROM
        $table INNER JOIN
        analysis_description ad USING (analysis_id)
      WHERE
        ad.analysis_id.displayable = 0
    /;
    is_rows_zero($self->dba, $sql_2, $desc_2);
  }
}

1;
