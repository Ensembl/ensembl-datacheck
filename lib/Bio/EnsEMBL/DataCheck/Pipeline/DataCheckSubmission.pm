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
Bio::EnsEMBL::DataCheck::Pipeline::DataCheckSubmission

=head1 DESCRIPTION
Perform housekeeping tasks that make it easier to seed jobs.

=cut

package Bio::EnsEMBL::DataCheck::Pipeline::DataCheckSubmission;

use strict;
use warnings;
use feature 'say';

use Time::Piece;

use base ('Bio::EnsEMBL::Hive::Process');

sub write_output {
  my $self = shift;

  # This module is a single point of entry into the pipeline, to enable
  # an eternal beekeeper to be seeded with multiple datacheck runs.
  # Pipeline-wide parameter propagation is switched on, so we just need
  # to pass on all the input parameters in order for subsequent modules
  # to have the data they need. There's no way in hive to get all the
  # parameters in a data structure, so need to do it the long-winded way,
  # which does at least make it explicit what we're doing...
  # We also add the job_id for this analysis, in order to be able to
  # associate results summaries with the relvant submission.

  my $params = {
    species      => $self->param('species'),
    antispecies  => $self->param('antispecies'),
    taxons       => $self->param('taxons'),
    antitaxons   => $self->param('antitaxons'),
    division     => $self->param('division'),
    run_all      => $self->param('run_all'),
    meta_filters => $self->param('meta_filters'),
    db_type      => $self->param('db_type'),

    datacheck_dir      => $self->param('datacheck_dir'),
    index_file         => $self->param('index_file'),
    history_file       => $self->param('history_file'),
    output_dir         => $self->param('output_dir'),
    config_file        => $self->param('config_file'),
    overwrite_files    => $self->param('overwrite_files'),
    datacheck_names    => $self->param('datacheck_names'),
    datacheck_patterns => $self->param('datacheck_patterns'),
    datacheck_groups   => $self->param('datacheck_groups'),
    datacheck_types    => $self->param('datacheck_types'),
    registry_file      => $self->param('registry_file'),
    old_server_uri     => $self->param('old_server_uri'),
    data_file_path     => $self->param('data_file_path'),

    failures_fatal => $self->param('failures_fatal'),

    parallelize_datachecks => $self->param('parallelize_datachecks'),

    tag           => $self->param('tag'),
    email         => $self->param('email'),
    report_per_db => $self->param('report_per_db'),
    report_all    => $self->param('report_all'),

    submission_job_id => $self->input_job->dbID,
  };
  $self->dataflow_output_id($params, 1);

  my $timestamp = $self->param('timestamp');
  $timestamp = localtime->cdate unless defined $timestamp;

  # A subset of the input parameters are stored in the 'datacheck_submission'
  # table, for easier subsequent retrieval than querying the native hive tables.
  my $datacheck_submission = {
    submission_job_id => $self->input_job->dbID,
    history_file      => $self->param('history_file'),
    output_dir        => $self->param('output_dir'),
    tag               => $self->param('tag'),
    email             => $self->param('email'),
    submitted         => $timestamp,
  };
  $self->dataflow_output_id($datacheck_submission, 3);

}

1;
