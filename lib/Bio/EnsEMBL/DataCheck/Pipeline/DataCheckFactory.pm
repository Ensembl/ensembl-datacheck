=head1 LICENSE
Copyright [2018] EMBL-European Bioinformatics Institute

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
Bio::EnsEMBL::DataCheck::Pipeline::DataCheckFactory

=head1 DESCRIPTION
A Hive module that uses the Manager to load a set of datachecks.

=cut

package Bio::EnsEMBL::DataCheck::Pipeline::DataCheckFactory;

use strict;
use warnings;
use feature 'say';

use Bio::EnsEMBL::DataCheck::Manager;

use base ('Bio::EnsEMBL::DataCheck::Pipeline::RunDataChecks');

sub run {
  my $self = shift;

  my $manager          = $self->param_required('manager');
  my $datacheck_params = $self->param_required('datacheck_params');

  my $datachecks = $manager->load_checks($datacheck_params);

  $self->param('datachecks', $datachecks);
}

sub write_output {
  my $self = shift;

  my $datachecks = $self->param('datachecks');

  foreach my $datacheck (@$datachecks) {
    my %output = (
      datacheck_names => [$datacheck->name],
    );

    $self->dataflow_output_id(\%output, 2);
  }
}

1;
