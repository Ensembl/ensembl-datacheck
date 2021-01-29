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
Bio::EnsEMBL::DataCheck::Pipeline::StoreResults

=head1 DESCRIPTION
Store summary stats in a hive database table.

=cut

package Bio::EnsEMBL::DataCheck::Pipeline::StoreResults;

use strict;
use warnings;
use feature 'say';

use base ('Bio::EnsEMBL::Hive::Process');

sub write_output {
  my $self = shift;

  my $output = {
    submission_job_id  => $self->param('submission_job_id'),
    dbname             => $self->param('dbname'),
    passed             => $self->param('datachecks_passed'),
    failed             => $self->param('datachecks_failed'),
    skipped            => $self->param('datachecks_skipped'),
  };

  $self->dataflow_output_id($output, 3);

  if (
    defined $self->param('email') &&
    $self->param('report_per_db') &&
    ($self->param('datachecks_failed') || $self->param('report_all'))
  ) {
    
    $self->dataflow_output_id({}, 4);
  }
}

1;
