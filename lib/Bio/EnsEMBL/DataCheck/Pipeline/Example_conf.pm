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
Bio::EnsEMBL::DataCheck::Pipeline::RunDataCheck

=head1 DESCRIPTION
A Hive module that runs an arbitrary datacheck.

=cut

package Bio::EnsEMBL::DataCheck::Pipeline::Example_conf;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');

use Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf;
use Bio::EnsEMBL::Hive::Version 2.4;

sub default_options {
  my ($self) = @_;
  return {
    %{$self->SUPER::default_options},

    pipeline_name => 'datacheck_example',

    species      => [],
    antispecies  => [],
    taxons       => [],
    antitaxons   => [],
    division     => [],
    run_all      => 0,
    meta_filters => {},

    datacheck_dir      => undef,
    index_file         => undef,
    history_file       => undef,
    output_dir         => undef,
    overwrite_files    => 1,
    datacheck_names    => [],
    datacheck_patterns => [],
    datacheck_groups   => [],
    datacheck_types    => [],

    failures_fatal => 1,

    db_type => 'core',
  };
}

# Force an automatic loading of the registry in all workers.
sub beekeeper_extra_cmdline_options {
  my ($self) = @_;

  my $options = join(' ',
    $self->SUPER::beekeeper_extra_cmdline_options,
    "-reg_conf ".$self->o('registry'),
  );
  
  return $options;
}

sub pipeline_analyses {
  my $self = shift @_;

  return [
    {
      -logic_name        => 'DbFactory',
      -module            => 'Bio::EnsEMBL::Production::Pipeline::Common::DbFactory',
      -max_retry_count   => 0,
      -input_ids         => [ {} ],
      -parameters        => {
                              species      => $self->o('species'),
                              antispecies  => $self->o('antispecies'),
                              taxons       => $self->o('taxons'),
                              antitaxons   => $self->o('antitaxons'),
                              division     => $self->o('division'),
                              run_all      => $self->o('run_all'),
                              meta_filters => $self->o('meta_filters'),
                              db_type      => $self->o('db_type'),
                            },
      -flow_into         => {
                              '2' => [
                                        'RunDataChecks', 'DataCheckFactory',
                                     ],
                            },
      -rc_name           => 'default',
    },

    {
      -logic_name        => 'SpeciesFactory',
      -module            => 'Bio::EnsEMBL::Production::Pipeline::Common::SpeciesFactory',
      -max_retry_count   => 0,
      -input_ids         => [ {} ],
      -parameters        => {
                              species      => $self->o('species'),
                              antispecies  => $self->o('antispecies'),
                              taxons       => $self->o('taxons'),
                              antitaxons   => $self->o('antitaxons'),
                              division     => $self->o('division'),
                              run_all      => $self->o('run_all'),
                              meta_filters => $self->o('meta_filters'),
                              db_type      => $self->o('db_type'),
                            },
      -flow_into         => {
                              '2' => ['RunDataChecks'],
                            },
      -rc_name           => 'default',
    },

    {
      -logic_name        => 'RunDataChecks',
      -module            => 'Bio::EnsEMBL::DataCheck::Pipeline::RunDataChecks',
      -analysis_capacity => 10,
      -max_retry_count   => 0,
      -parameters        => {
                              datacheck_dir      => $self->o('datacheck_dir'),
                              index_file         => $self->o('index_file'),
                              history_file       => $self->o('history_file'),
                              output_dir         => $self->o('output_dir'),
                              output_filename    => '#dbname#',
                              overwrite_files    => $self->o('overwrite_files'),
                              datacheck_names    => $self->o('datacheck_names'),
                              datacheck_patterns => $self->o('datacheck_patterns'),
                              datacheck_groups   => $self->o('datacheck_groups'),
                              datacheck_types    => $self->o('datacheck_types'),
                              failures_fatal     => $self->o('failures_fatal'),
                            },
      -rc_name           => 'default',
    },

    {
      -logic_name        => 'DataCheckFactory',
      -module            => 'Bio::EnsEMBL::DataCheck::Pipeline::DataCheckFactory',
      -analysis_capacity => 10,
      -max_retry_count   => 0,
      -parameters        => {
                              datacheck_dir      => $self->o('datacheck_dir'),
                              index_file         => $self->o('index_file'),
                              history_file       => $self->o('history_file'),
                              output_dir         => $self->o('output_dir'),
                              output_filename    => '#dbname#',
                              overwrite_files    => $self->o('overwrite_files'),
                              datacheck_names    => $self->o('datacheck_names'),
                              datacheck_patterns => $self->o('datacheck_patterns'),
                              datacheck_groups   => $self->o('datacheck_groups'),
                              datacheck_types    => $self->o('datacheck_types'),
                              failures_fatal     => $self->o('failures_fatal'),
                            },
      -rc_name           => 'default',
      -flow_into         => {
                              '2->A' => {'DataCheckFan'    => INPUT_PLUS()},
                              'A->1' => {'DataCheckFunnel' => INPUT_PLUS()},
                            },
    },

    {
      -logic_name        => 'DataCheckFan',
      -module            => 'Bio::EnsEMBL::DataCheck::Pipeline::DataCheckFan',
      -analysis_capacity => 100,
      -max_retry_count   => 0,
      -parameters        => {
                              datacheck_dir      => $self->o('datacheck_dir'),
                              index_file         => $self->o('index_file'),
                              history_file       => $self->o('history_file'),
                              output_dir         => $self->o('output_dir'),
                              output_filename    => '#dbname#',
                              overwrite_files    => $self->o('overwrite_files'),
                              datacheck_names    => $self->o('datacheck_names'),
                              datacheck_patterns => $self->o('datacheck_patterns'),
                              datacheck_groups   => $self->o('datacheck_groups'),
                              datacheck_types    => $self->o('datacheck_types'),
                              failures_fatal     => $self->o('failures_fatal'),
                            },
      -rc_name           => 'default',
      -flow_into         => {
                              '1' => ['?accu_name=results&accu_address=[]'],
                            },
    },

    {
      -logic_name        => 'DataCheckFunnel',
      -module            => 'Bio::EnsEMBL::DataCheck::Pipeline::DataCheckFunnel',
      -analysis_capacity => 10,
      -batch_size        => 100,
      -max_retry_count   => 0,
      -parameters        => {
                              datacheck_dir      => $self->o('datacheck_dir'),
                              index_file         => $self->o('index_file'),
                              history_file       => $self->o('history_file'),
                              output_dir         => $self->o('output_dir'),
                              output_filename    => '#dbname#',
                              overwrite_files    => $self->o('overwrite_files'),
                              datacheck_names    => $self->o('datacheck_names'),
                              datacheck_patterns => $self->o('datacheck_patterns'),
                              datacheck_groups   => $self->o('datacheck_groups'),
                              datacheck_types    => $self->o('datacheck_types'),
                              failures_fatal     => $self->o('failures_fatal'),
                            },
      -rc_name           => 'default',
    },

  ];
}

sub resource_classes {
  my ($self) = @_;
  return {
    'default' => {'LSF' => '-q production-rh7 -M 500 -R "rusage[mem=500]"'},
  }
}

1;
