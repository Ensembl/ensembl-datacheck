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
Bio::EnsEMBL::DataCheck::Pipeline::DbDataChecks_conf

=head1 DESCRIPTION
A pipeline for executing datachecks across databases.

=cut

package Bio::EnsEMBL::DataCheck::Pipeline::DbDataChecks_conf;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');

use Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf;
use Bio::EnsEMBL::Hive::Version 2.5;

sub default_options {
  my ($self) = @_;
  return {
    %{$self->SUPER::default_options},

    pipeline_name => 'db_datachecks',

    species      => [],
    taxons       => [],
    division     => [],
    run_all      => 0,
    antispecies  => [],
    antitaxons   => [],
    meta_filters => {},
    dbname       => [],
    db_type      => 'core',

    datacheck_dir      => undef,
    index_file         => undef,
    history_file       => undef,
    output_dir         => undef,
    config_file        => undef,
    overwrite_files    => 1,
    datacheck_names    => [],
    datacheck_patterns => [],
    datacheck_groups   => [],
    datacheck_types    => [],
    registry_file      => undef,
    old_server_uri     => undef,
    data_file_path     => undef,

    failures_fatal => 0,

    parallelize_datachecks => 0,

    tag           => undef,
    timestamp     => undef,
    email         => undef,
    report_per_db => 0,
    report_all    => 0,
  };
}

# Implicit parameter propagation throughout the pipeline.
sub hive_meta_table {
  my ($self) = @_;
  
  return {
    %{$self->SUPER::hive_meta_table},
    'hive_use_param_stack' => 1,
  };
}

sub pipeline_create_commands {
  my ($self) = @_;

  my $submission_table_sql = q/
    CREATE TABLE datacheck_submission (
      submission_job_id INT PRIMARY KEY,
      history_file VARCHAR(255) NULL,
      output_dir VARCHAR(255) NULL,
      tag VARCHAR(255) NULL,
      email VARCHAR(255) NULL,
      submitted VARCHAR(255) NULL
    );
  /;

  my $results_table_sql = q/
    CREATE TABLE datacheck_results (
      submission_job_id INT,
      dbname VARCHAR(255) NOT NULL,
      passed INT,
      failed INT,
      skipped INT,
      INDEX submission_job_id_idx (submission_job_id)
    );
  /;

  my $result_table_sql = q/
    CREATE TABLE result (
      job_id INT PRIMARY KEY,
      output TEXT
    );
  /;

  my $drop_input_id_index = q/
    ALTER TABLE job DROP KEY input_id_stacks_analysis;
  /;

  my $extend_input_id = q/
    ALTER TABLE job MODIFY input_id TEXT;
  /;

  return [
    @{$self->SUPER::pipeline_create_commands},
    $self->db_cmd($submission_table_sql),
    $self->db_cmd($results_table_sql),
    $self->db_cmd($result_table_sql),
    $self->db_cmd($drop_input_id_index),
    $self->db_cmd($extend_input_id),
  ];
}

sub pipeline_analyses {
  my $self = shift @_;

  return [
    {
      -logic_name        => 'DataCheckSubmission',
      -module            => 'Bio::EnsEMBL::DataCheck::Pipeline::DataCheckSubmission',
      -analysis_capacity => 1,
      -max_retry_count   => 1,
      -parameters        => {
                              species      => $self->o('species'),
                              taxons       => $self->o('taxons'),
                              division     => $self->o('division'),
                              run_all      => $self->o('run_all'),
                              antispecies  => $self->o('antispecies'),
                              antitaxons   => $self->o('antitaxons'),
                              meta_filters => $self->o('meta_filters'),
                              dbname       => $self->o('dbname'),
                              db_type      => $self->o('db_type'),

                              datacheck_dir      => $self->o('datacheck_dir'),
                              index_file         => $self->o('index_file'),
                              history_file       => $self->o('history_file'),
                              output_dir         => $self->o('output_dir'),
                              config_file        => $self->o('config_file'),
                              overwrite_files    => $self->o('overwrite_files'),
                              datacheck_names    => $self->o('datacheck_names'),
                              datacheck_patterns => $self->o('datacheck_patterns'),
                              datacheck_groups   => $self->o('datacheck_groups'),
                              datacheck_types    => $self->o('datacheck_types'),
                              registry_file      => $self->o('registry_file'),
                              old_server_uri     => $self->o('old_server_uri'),
                              data_file_path     => $self->o('data_file_path'),

                              failures_fatal     => $self->o('failures_fatal'),

                              parallelize_datachecks => $self->o('parallelize_datachecks'),

                              tag           => $self->o('tag'),
                              timestamp     => $self->o('timestamp'),
                              email         => $self->o('email'),
                              report_per_db => $self->o('report_per_db'),
                              report_all    => $self->o('report_all'),
                            },
      -rc_name           => 'default',
      -flow_into         => {
                              '1' => ['DbFactory'],
                              '3' => ['?table_name=datacheck_submission'],
                            },
    },

    {
      -logic_name        => 'DbFactory',
      -module            => 'Bio::EnsEMBL::Production::Pipeline::Common::DbFactory',
      -analysis_capacity => 10,
      -max_retry_count   => 0,
      -flow_into         => {
                              '2->A' =>
                                WHEN('#parallelize_datachecks#' => 
                                  ['DataCheckFactory'],
                                ELSE 
                                  ['RunDataChecks']
                                ),
                              'A->1' => ['DataCheckSummary'],
                            },
      -rc_name           => 'default',
    },

    {
      -logic_name        => 'RunDataChecks',
      -module            => 'Bio::EnsEMBL::DataCheck::Pipeline::RunDataChecks',
      -analysis_capacity => 10,
      -max_retry_count   => 0,
      -rc_name           => '2GB',
      -flow_into         => {
                              '1' => ['StoreResults'],
                             '-1' => ['RunDataChecks_High_mem']
                            },
    },

    {
      -logic_name        => 'RunDataChecks_High_mem',  
      -module            => 'Bio::EnsEMBL::DataCheck::Pipeline::RunDataChecks',
      -analysis_capacity => 10,
      -max_retry_count   => 0,
      -rc_name           => '8GB',
      -flow_into         => {
                              '1' => ['StoreResults'],
                            },
    },

    {
      -logic_name        => 'DataCheckFactory',
      -module            => 'Bio::EnsEMBL::DataCheck::Pipeline::DataCheckFactory',
      -analysis_capacity => 10,
      -max_retry_count   => 0,
      -rc_name           => 'default',
      -flow_into         => {
                              '2->A' => ['DataCheckFan'],
                              'A->1' => ['DataCheckFunnel'],
                            },
    },

    {
      -logic_name        => 'DataCheckFan',
      -module            => 'Bio::EnsEMBL::DataCheck::Pipeline::DataCheckFan',
      -analysis_capacity => 100,
      -max_retry_count   => 0,
      -rc_name           => '2GB',
      -flow_into         => {
                              '1' => ['?accu_name=results&accu_address=[]'],
                             '-1' => ['DataCheckFan_High_mem'] 
                            },
    },

    {
      -logic_name        => 'DataCheckFan_High_mem',
      -module            => 'Bio::EnsEMBL::DataCheck::Pipeline::DataCheckFan',
      -analysis_capacity => 100,
      -max_retry_count   => 0,
      -rc_name           => '8GB',
      -flow_into         => {
                              '1' => ['?accu_name=results&accu_address=[]'],
                            },
    },

    {
      -logic_name        => 'DataCheckFunnel',
      -module            => 'Bio::EnsEMBL::DataCheck::Pipeline::DataCheckFunnel',
      -analysis_capacity => 1,
      -batch_size        => 100,
      -max_retry_count   => 0,
      -rc_name           => '2GB',
      -flow_into         => {
                              '1' => ['StoreResults'],
                            },
    },

    {
      -logic_name        => 'StoreResults',
      -module            => 'Bio::EnsEMBL::DataCheck::Pipeline::StoreResults',
      -analysis_capacity => 10,
      -max_retry_count   => 1,
      -rc_name           => 'default',
      -flow_into         => {
                              '3' => ['?table_name=datacheck_results'],
                              '4' => ['EmailReport'],
                            },
    },

    {
      -logic_name        => 'EmailReport',
      -module            => 'Bio::EnsEMBL::DataCheck::Pipeline::EmailReport',
      -analysis_capacity => 10,
      -batch_size        => 100,
      -max_retry_count   => 0,
      -rc_name           => 'default',
    },

    {
      -logic_name        => 'DataCheckSummary',
      -module            => 'Bio::EnsEMBL::DataCheck::Pipeline::DataCheckSummary',
      -analysis_capacity => 10,
      -max_retry_count   => 0,
      -rc_name           => 'default',
      -flow_into         => {
                              '1' => ['?table_name=result'],
                            },
    },

  ];
}

sub resource_classes {
  my ($self) = @_;

  return {
    'default' => {LSF => '-q production-rh74 -M 500 -R "rusage[mem=500]"'},
    '2GB'     => {LSF => '-q production-rh74 -M 2000 -R "rusage[mem=2000]"'},
    '4GB'     => {LSF => '-q production-rh74 -M 4000 -R "rusage[mem=4000]"'},
    '8GB'     => {LSF => '-q production-rh74 -M 8000 -R "rusage[mem=8000]"'},
    '16GB'    => {LSF => '-q production-rh74 -M 16000 -R "rusage[mem=16000]"'},
  }
}

1;
