# Copyright [2018] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;
use feature 'say';

use Bio::EnsEMBL::DataCheck::Pipeline::RunDataChecks;
use Bio::EnsEMBL::Hive::AnalysisJob;
use Bio::EnsEMBL::Test::MultiTestDB;

use FindBin; FindBin::again();
use JSON;
use Path::Tiny;
use Test::Exception;
use Test::More;

my $test_db_dir = $FindBin::Bin;

my $species  = 'drosophila_melanogaster';
my $db_type  = 'core';
my $dba_type = 'Bio::EnsEMBL::DBSQL::DBAdaptor';
my $testdb   = Bio::EnsEMBL::Test::MultiTestDB->new($species, $test_db_dir);
my $dba      = $testdb->get_DBAdaptor($db_type);

my $datacheck_dir = "$FindBin::Bin/TestChecks";
my $index_file    = "$FindBin::Bin/index.json";

my $module = 'Bio::EnsEMBL::DataCheck::Pipeline::RunDataChecks';

diag('Methods');
my @hive_methods   = qw(param_defaults fetch_input run write_output);
my @module_methods = qw(datacheck_params set_dba_param set_registry_param);
can_ok($module, @hive_methods);
can_ok($module, @module_methods);

my $obj = $module->new();
my $job_obj = Bio::EnsEMBL::Hive::AnalysisJob->new;
$obj->input_job($job_obj);

subtest 'Default attributes', sub {
  my $param_defaults = $obj->param_defaults();
  $obj->input_job->param_init($param_defaults);
  is($obj->param('failures_fatal'), 1, 'param_defaults method: failures_fatal');
};

subtest 'Parameter instantiation: Manager', sub {
  $obj->param('datacheck_dir', '/datacheck/dir');
  $obj->param('index_file', '/path/to/index/file');
  $obj->param('history_file', '/path/to/history/file');
  $obj->param('output_dir', '/output/dir');
  $obj->param('output_filename', 'tap_output');
  $obj->param('overwrite_files', 0);
  $obj->param('datacheck_names', ['DbCheck_1', 'DbCheck_4']);
  $obj->param('datacheck_patterns', ['BaseCheck']);
  $obj->param('datacheck_groups', ['base']);
  $obj->param('datacheck_types', ['advisory']);

  $obj->fetch_input();
  my $manager = $obj->param('manager');
  isa_ok($manager, 'Bio::EnsEMBL::DataCheck::Manager');

  is($manager->datacheck_dir, '/datacheck/dir', 'Datacheck directory is set correctly');
  is($manager->index_file, '/path/to/index/file', 'Index file is set correctly');
  is($manager->history_file, '/path/to/history/file', 'History file is set correctly');
  is($manager->output_file, '/output/dir/tap_output.txt', 'Output file is set correctly');
  is($manager->overwrite_files, 0, 'Overwrite flag is set correctly');
  is_deeply($manager->names, ['DbCheck_1', 'DbCheck_4'], 'Datacheck names are set correctly');
  is_deeply($manager->patterns, ['BaseCheck'], 'Datacheck patterns are set correctly');
  is_deeply($manager->groups, ['base'], 'Datacheck groups are set correctly');
  is_deeply($manager->datacheck_types, ['advisory'], 'Datacheck types are set correctly');

  $obj->param('datacheck_dir', undef);
  $obj->param('index_file', undef);
  $obj->param('history_file', undef);
  $obj->param('output_dir', undef);
  $obj->param('output_filename', undef);
  $obj->param('overwrite_files', 1);
  $obj->param('datacheck_names', []);
  $obj->param('datacheck_patterns', []);
  $obj->param('datacheck_groups', []);
  $obj->param('datacheck_types', []);
};

subtest 'Parameter instantiation: DbCheck with DBA', sub {
  $obj->param('dba', $dba);

  $obj->fetch_input();
  my $datacheck_params = $obj->param('datacheck_params');

  is($$datacheck_params{dba}, $dba, 'DBA set correctly');
  is($$datacheck_params{dba_species_only}, 0, 'DBA species flag set correctly');

  $obj->param('dba', undef);
};

subtest 'Parameter instantiation: DbCheck with dbname', sub {
  $obj->param('dbname', $dba->dbc->dbname);

  $obj->fetch_input();
  my $datacheck_params = $obj->param('datacheck_params');

  is($$datacheck_params{dba}, $dba, 'DBA set correctly');
  is($$datacheck_params{dba_species_only}, 0, 'DBA species flag set correctly');

  $obj->param('dbname', undef);
};

subtest 'Parameter instantiation: DbCheck with non-existent dbname', sub {
  $obj->param('dbname', 'rhubarb_and_custard');
  
  throws_ok(
    sub { $obj->fetch_input() },
    qr/No databases matching/, "Fail if database doesn't exist");

  $obj->param('dbname', undef);
};

subtest 'Parameter instantiation: DbCheck with species only', sub {
  $obj->param('species', $species);
  # Default group is 'core'

  $obj->fetch_input();
  my $datacheck_params = $obj->param('datacheck_params');

  is($$datacheck_params{dba}, $dba, 'DBA set correctly');
  is($$datacheck_params{dba_species_only}, 1, 'DBA species flag set correctly');

  $obj->param('species', undef);
};

subtest 'Parameter instantiation: DbCheck with species and group', sub {
  $obj->param('species', $species);
  $obj->param('group', $db_type);

  $obj->fetch_input();
  my $datacheck_params = $obj->param('datacheck_params');

  is($$datacheck_params{dba}, $dba, 'DBA set correctly');
  is($$datacheck_params{dba_species_only}, 1, 'DBA species flag set correctly');

  $obj->param('species', undef);
  $obj->param('group', 'core');
};

subtest 'Parameter instantiation: DbCheck with species and wrong group', sub {
  $obj->param('species', $species);
  $obj->param('group', 'otherfeatures');

  throws_ok(
    sub { $obj->fetch_input() },
    qr/No otherfeatures database for $species/, "Fail if group doesn't exist");

  $obj->param('species', undef);
  $obj->param('group', 'core');
};

subtest 'Parameter instantiation: DbCheck registry parameters', sub {
  $obj->param('registry_file', '/path/to/registry');
  $obj->param('server_uri', 'mysql_uri_1');
  $obj->param('old_server_uri', 'mysql_uri_2');

  $obj->fetch_input();
  my $datacheck_params = $obj->param('datacheck_params');

  is($$datacheck_params{registry_file}, '/path/to/registry', 'Registry file is set correctly');
  is($$datacheck_params{server_uri}, 'mysql_uri_1', 'Server URI is set correctly');
  is($$datacheck_params{old_server_uri}, 'mysql_uri_2', 'Old server URI is set correctly');

  $obj->param('registry_file', undef);
  $obj->param('server_uri', undef);
  $obj->param('old_server_uri', undef);
};

done_testing();
