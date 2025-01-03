=head1 LICENSE

Copyright [2018-2025] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::AnalysisWebDataFormat;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::Utils::SqlHelper;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'AnalysisWebDataFormat',
  DESCRIPTION    => 'Checks if entries in the web_data column of the analysis_description table have the correct format',
  GROUPS         => ['funcgen'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['funcgen'],
  TABLES         => ['analysis_description']
};

sub tests {
  my ($self) = @_;
  SKIP: {
    my $funcgen_dba = $self->get_dba(undef, 'funcgen');
    skip 'No funcgen database', 1 unless defined $funcgen_dba;

    my $desc = "Check if web_data column in analysis_description table is formatted correctly";
    my $test_name = "ReadFile path encrypted";

    my $sql = qq/
        select web_data
        from analysis_description
        where web_data is not null
        and web_data <> \'{}\'
        and trim(web_data) <> \'\'/;

    my $web_data = $funcgen_dba->dbc->sql_helper->execute(-SQL => $sql);

    my $num_failed = 0;
    foreach my $web_data_entry (@$web_data){
      if ($web_data_entry->[0] !~ m/^{.+:.+}$/){
        $num_failed ++;
      }
    }
    ok( $num_failed == 0, $desc );
  }
}

1;

