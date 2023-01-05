=head1 LICENSE

Copyright [2018-2023] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::ComparePreviousVersionProbeFeatures;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::Utils::SqlHelper;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'ComparePreviousVersionProbeFeatures',
  DESCRIPTION    => 'Checks for loss of probes between database versions',
  GROUPS         => ['probe_mapping'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['funcgen'],
  TABLES         => ['probe_feature']
};

sub tests {
  my ($self) = @_;
  SKIP: {
    my $previous_dba = $self->get_old_dba();

    skip 'No previous version of database', 1 unless defined $previous_dba;

    my $min_proportion = 10.0;

    my $helper  = $self->dba->dbc->sql_helper;
    my $previous_helper  = $previous_dba->dbc->sql_helper;
    my $sql = qq/
        select count(*)
        from probe_feature/;
    my $probe_features_count = $helper->execute_single_result(
          -SQL => $sql,
        );
    my $previous_probe_features_count = $previous_helper->execute_single_result(
          -SQL => $sql,
        );


    my $difference = abs($probe_features_count - $previous_probe_features_count);
    my $average = ($probe_features_count + $previous_probe_features_count)/2;
    my $difference_percentage = ($difference / $average) * 100;
    my $test_description = "Database ".$self->dba->dbc->dbname." has ".$probe_features_count.
        " probe features and database ".$previous_dba->dbc->dbname." has ".$previous_probe_features_count.
        ". The difference is ".sprintf("%.2f",$difference_percentage).
	"\%.\nTest will fail if the difference is >".sprintf("%.2f", $min_proportion)."\%.";

    ok($difference_percentage <= $min_proportion, $test_description);

  }
}

1;

