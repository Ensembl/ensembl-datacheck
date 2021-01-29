=head1 LICENSE
Copyright [2018-2021] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 NAME
Bio::EnsEMBL::DataCheck::Pipeline::DataCheckFunnel

=head1 DESCRIPTION
A Hive module that uses the Manager to load a set of datachecks.

=cut

package Bio::EnsEMBL::DataCheck::Pipeline::DataCheckFunnel;

use strict;
use warnings;
use feature 'say';

use Bio::EnsEMBL::DataCheck::Manager;
use Path::Tiny;

use base ('Bio::EnsEMBL::DataCheck::Pipeline::RunDataChecks');

sub run {
  my $self = shift;

  my $manager           = $self->param_required('manager');
  my $datacheck_params  = $self->param_required('datacheck_params');
  my $results           = $self->param_required('results');

  my $datachecks = $manager->load_checks(%$datacheck_params);

  my ($passed, $failed, $skipped) = (0, 0, 0);
  my $output = '';

  foreach my $result (@$results) {
    $passed++  if $$result{passed} == 1;
    $failed++  if $$result{passed} == 0;
    $skipped++ if $$result{passed} == 1 && !defined $$result{finished};

    $output .= $$result{output};

    # We've loaded the datachecks anew, so we need to
    # fill in the results from the fan jobs.
    foreach my $datacheck (@$datachecks) {
      if ($$result{name} eq $datacheck->name) {
        $datacheck->output($$result{output});
        $datacheck->_passed($$result{passed});
        $datacheck->_started($$result{started});
        $datacheck->_finished($$result{finished});
      }
    }
  }

  if (defined $self->param('output_file')) {
    my $output_file = $self->param('output_file');

    if (-s $output_file) {
      my $manager = $self->param_required('manager');
      if ($manager->overwrite_files) {
        path($output_file)->spew($output);
      } else {
        die "'$output_file' exists, and will not be overwritten";
      }
    } else {
      path($output_file)->parent->mkpath;
      path($output_file)->spew($output);
    }
  }

  if (defined $self->param('history_file')) {
    $manager->write_history($datachecks);
  }

  $self->param('passed',  $passed);
  $self->param('failed',  $failed);
  $self->param('skipped', $skipped);

  $self->param('datachecks', $datachecks);
}

1;
