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

package Bio::EnsEMBL::DataCheck::Checks::GenomeStatistics;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'GenomeStatistics',
  DESCRIPTION => 'Genome statistics are present and correct',
  GROUPS      => ['statistics'],
  DB_TYPES    => ['core'],
  TABLES      => ['attrib_type', 'genome_statistics']
};

sub tests {
  my ($self) = @_;

  my @statistic_names = qw/
    coding_cnt
    pseudogene_cnt
    noncoding_cnt
    noncoding_cnt_s
    noncoding_cnt_l
    noncoding_cnt_m
    transcript
    ref_length
    total_length
  /;

  my $ga = $self->dba->get_adaptor("GenomeContainer");

  my $statistics = $ga->fetch_all_statistics();

  my %statistic_counts = map {$_ => 0} @statistic_names;

  foreach my $statistic (@$statistics) {
    if (exists $statistic_counts{$statistic->statistic}) {
      $statistic_counts{$statistic->statistic}++;

      unless ($statistic->statistic eq 'transcript') {
        my $desc = "Statistic name " . $statistic->statistic . " matches attribute code";
        is($statistic->statistic, $statistic->code, $desc);
      }
    }
  }

  foreach my $statistic_name (@statistic_names) {
    my $desc = "Statistic $statistic_name exists";
    is($statistic_counts{$statistic_name}, 1, $desc);
  }
}

1;

