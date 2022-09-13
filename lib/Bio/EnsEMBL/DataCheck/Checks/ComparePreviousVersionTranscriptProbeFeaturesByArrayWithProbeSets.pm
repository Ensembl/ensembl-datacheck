=head1 LICENSE

Copyright [2018-2022] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::ComparePreviousVersionTranscriptProbeFeaturesByArrayWithProbeSets;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::Utils::SqlHelper;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'ComparePreviousVersionTranscriptProbeFeaturesByArrayWithProbeSets',
  DESCRIPTION    => 'hecks for loss of probes features from transcript mappings for each array that is organised into probe sets.',
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

    my $current_probeset_size = get_average_probeset_size_per_array($self->dba);
    my $previous_probeset_size = get_average_probeset_size_per_array($previous_dba);
    my $num_current_probefeatures_array = get_counts($self->dba);
    my $num_previous_probefeatures_array = get_counts($previous_dba);
    my $current_normalized = normalize($num_current_probefeatures_array, $current_probeset_size);
    my $previous_normalized = normalize($num_previous_probefeatures_array, $previous_probeset_size);
    my $min_proportion = 0.1;
    foreach my $array_name (keys %$current_normalized){
      if (exists $$previous_normalized{$array_name}){
        my $difference = abs($$current_normalized{$array_name} - $$previous_normalized{$array_name});
        my $average = ($$current_normalized{$array_name} + $$previous_normalized{$array_name})/2;
        my $difference_percentage = $difference / $average;
        my $test_description = "Database ".$self->dba->dbc->dbname.", array ".$array_name." has ".
            $$current_normalized{$array_name}." (normalized) probe features, and database ".
            $previous_dba->dbc->dbname.", array ".$array_name." has ".$$previous_normalized{$array_name}.
            " (normalized) probe features. The difference is ".$difference_percentage;

        ok($difference_percentage <= $min_proportion, $test_description);
      }

    }
  }
}

sub get_average_probeset_size_per_array{
  my $db = shift;

  my $sql = qq/
    select array.name, count(distinct probe_id)\/count(distinct probe_set_id)
    from probe_set
    join probe using (probe_set_id)
    join array_chip on (array_chip.array_chip_id = probe.array_chip_id)
    join array using (array_id)
    group by array.name, array.vendor/;

  my $avg_probeset_size_array = $db->dbc->sql_helper->execute_into_hash( -SQL => $sql );

  return $avg_probeset_size_array;
}

sub get_counts{
  my $db = shift;
  my $sql = qq/
    select array.name, count(distinct probe_feature.probe_feature_id)
    from array join array_chip using (array_id)
    join probe using (array_chip_id)
    join probe_feature using (probe_id)
    join analysis using (analysis_id)
    where analysis.logic_name like \"%transcript%\"
    group by analysis.logic_name, array.name/;

  my $num_probefeatures_array = $db->dbc->sql_helper->execute_into_hash( -SQL => $sql );

  return $num_probefeatures_array;
}

sub normalize{
  my ($counts, $size) = @_;

  my %normalized_counts;
  foreach my $array_name (keys %$counts) {
    if (exists $$size{$array_name}){
      $normalized_counts{$array_name}= $$counts{$array_name} / $$size{$array_name};
    }
  }

  return \%normalized_counts;
}

1;

