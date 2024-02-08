=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::ComparePreviousVersionTranscriptProbeFeaturesByArray;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'ComparePreviousVersionTranscriptProbeFeaturesByArray',
  DESCRIPTION    => 'Checks for loss of probes features from transcript mappings for each array that is not organised into probe sets.',
  GROUPS         => ['probe_mapping'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['funcgen'],
  TABLES         => ['analysis', 'array', 'array_chip', 'probe', 'probe_feature']
};

sub tests {
  my ($self) = @_;
  SKIP: {
    my $previous_dba = $self->get_old_dba();

    skip 'No previous version of database', 1 unless defined $previous_dba;

    my $desc_decrease = "Checking if number of probe features from transcript mapping has decreased between ".
                 $self->dba->dbc->dbname.' and '.$previous_dba->dbc->dbname;
    my $desc_increase = "Checking if number of probe features from transcript mapping has increased between ".
                 $self->dba->dbc->dbname.' and '.$previous_dba->dbc->dbname;
    my $min_proportion = 0.9;

    my $sql = qq/
      select array.name, count(distinct probe_feature.probe_feature_id)
      from array join array_chip using (array_id)
      join probe using (array_chip_id) join probe_feature using (probe_id)
      join analysis using (analysis_id)
      where analysis.logic_name like \'%transcript%\'
      group by analysis.logic_name, array.name/;

    row_subtotals($self->dba, $previous_dba, $sql, undef, $min_proportion, $desc_decrease);
    row_subtotals($previous_dba, $self->dba, $sql, undef, $min_proportion, $desc_increase);


  }
}

1;

