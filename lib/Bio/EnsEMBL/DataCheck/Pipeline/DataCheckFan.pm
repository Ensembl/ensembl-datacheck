=head1 LICENSE
Copyright [2018-2020] EMBL-European Bioinformatics Institute

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
Bio::EnsEMBL::DataCheck::Pipeline::DataCheckFan

=head1 DESCRIPTION
A Hive module that runs an arbitrary datacheck.

=cut

package Bio::EnsEMBL::DataCheck::Pipeline::DataCheckFan;

use strict;
use warnings;
use feature 'say';

use base ('Bio::EnsEMBL::DataCheck::Pipeline::RunDataChecks');

sub run {
  my $self = shift;

  my $manager          = $self->param_required('manager');
  my $datacheck_params = $self->param_required('datacheck_params');

  my $datachecks = $manager->load_checks(%$datacheck_params);

  my $datacheck;
  if (scalar @$datachecks == 1) {
    $datacheck = $$datachecks[0];
  } elsif (scalar @$datachecks == 0) {
    my $names = join(", ", @{ $self->param('datacheck_names') });
    $self->throw("No datacheck found: $names");
  } else {
    my $names = join(", ", @{ $self->param('datacheck_names') });
    $self->throw("Multiple datachecks found: $names");
  }

  my $result = $datacheck->run();

  # A non-zero $result indicates failure.
  if ($result) {
    my $msg = "Datacheck failed: " . $datacheck->name;
    $msg .= "\n" . $datacheck->output;

    if ($self->param_required('failures_fatal')) {
      die $msg;
    } else {
      $self->warning($msg);
    }
  }

  $self->param('datacheck', $datacheck);
}

sub write_output {
  my $self = shift;

  my $datacheck = $self->param('datacheck');

  my %output = (
    results =>
      {
        name     => $datacheck->name,
        output   => $datacheck->output,
        started  => $datacheck->_started,
        finished => $datacheck->_finished,
        passed   => $datacheck->_passed,
      },
  );

  $self->dataflow_output_id(\%output, 1);
}

1;
