# Copyright [2018-2019] EMBL-European Bioinformatics Institute
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

use Bio::EnsEMBL::DataCheck::DbCheck;
use Bio::EnsEMBL::Test::MultiTestDB;

use FindBin; FindBin::again();
use Path::Tiny;
use Test::Exception;
use Test::More;

use lib "$FindBin::Bin/TestChecks";
use DbCheck_1;
use DbCheck_2;
use DbCheck_3;
use DbCheck_4;
use DbCheck_5;

my $test_db_dir = $FindBin::Bin;
my $dba_type    = 'Bio::EnsEMBL::DBSQL::DBAdaptor';

my $species = 'drosophila_melanogaster';
my $db_type = 'core';
my $testdb  = Bio::EnsEMBL::Test::MultiTestDB->new($species, $test_db_dir);

my $dba     = $testdb->get_DBAdaptor($db_type);

# Note that you cannot, by design, create a DbCheck object; datachecks
# must inherit from it and define mandatory, read-only parameters that
# are specific to that particular datacheck. So there's a limited amount
# of testing that we can do on the base class, the functionality is
# tested on a subclass.

my $module = 'Bio::EnsEMBL::DataCheck::DbCheck';

diag('Fixed attributes');
can_ok($module, qw(db_types tables per_db force));

diag('Runtime attributes');
can_ok($module, qw(dba dba_species_only registry_file server_uri registry old_server_uri data_file_path dba_list));

diag('Methods');
can_ok($module, qw(
  species get_dba get_dna_dba get_old_dba 
  skip_datacheck run_datacheck skip_tests tests run
  verify_db_type check_history table_dates));

# As well as being a nice way to encapsulate sets of tests, the use of
# subtests here is necessary, because the behaviour we are testing
# involves running tests, and we need to isolate that from the reports
# of this test (i.e. DbCheck.t).

subtest 'Minimal DbCheck with passing tests', sub {
  my $dbcheck = TestChecks::DbCheck_1->new(
    dba => $dba,
  );
  isa_ok($dbcheck, $module);

  my $name = $dbcheck->name;

  is_deeply($dbcheck->db_types, [],        'db_types attribute defaults to empty list');
  is_deeply($dbcheck->tables,   [],        'tables attribute defaults to empty list');
  is($dbcheck->per_db,          0,         'per_db attribute defaults to zero');
  isa_ok($dbcheck->dba,         $dba_type, 'dba attribute');

  is($dbcheck->skip_tests(),     undef, 'skip_tests method undefined');
  is($dbcheck->verify_db_type(), undef, 'verify_db_type method undefined');
  is($dbcheck->check_history(),  undef, 'check_history method undefined');
  is($dbcheck->skip_datacheck(), undef, 'skip_datacheck method undefined');

  # The tests that are run are Test::More tests. Running them within a test
  # is a bit confusing. To simulate a proper test of the tests, need to reset
  # the Test::More framework.
  Test::More->builder->reset();
  my $result = $dbcheck->run;
  diag("Test enumeration reset by the datacheck object ($name)");

  is($result, 0, 'test passes');

  my $started = $dbcheck->_started;
  sleep(2);

  like($dbcheck->output, qr/# Subtest\: $name/m, 'tests ran as subtests');
  like($dbcheck->output, qr/^\s+1\.\.2/m,         '2 subtests ran successfully');
  like($dbcheck->output, qr/^\s+ok 1 - $name/m,  'test ran successfully');
  like($dbcheck->output, qr/^\s+1\.\.1/m,         'test ran with a plan');

  like($dbcheck->_started,  qr/^\d+$/, '_started attribute has numeric value');
  like($dbcheck->_finished, qr/^\d+$/, '_finished attribute has numeric value');
  is($dbcheck->_passed,     1,         '_passed attribute is true');

  # Now that we've run the test, we've got something to compare against
  # the database tables; because specific tables are not given, all will
  # be checked.
  my ($skip, $skip_reason) = $dbcheck->check_history();
  is($skip, 1, 'History used to skip datacheck');
  is($skip_reason, 'Database tables not updated since last run', 'Correct skip reason');

  ($skip, $skip_reason) = $dbcheck->skip_datacheck();
  is($skip, 1, 'History used to skip datacheck');
  is($skip_reason, 'Database tables not updated since last run', 'Correct skip reason');

  Test::More->builder->reset();
  $result = $dbcheck->run;
  diag("Test enumeration reset by the datacheck object ($name)");

  is($result, 0, 'skipped test passes');

  cmp_ok($dbcheck->_started, '>', $started, '_started attribute changed when datacheck skipped');
  is($dbcheck->_finished,    undef,         '_finished attribute undefined when datacheck skipped');
  is($dbcheck->_passed,      1,             '_passed attribute remains true');
};

subtest 'DbCheck with failing test', sub {
  my $dbcheck = TestChecks::DbCheck_2->new(
    dba => $dba,
  );
  isa_ok($dbcheck, $module);

  my $name = $dbcheck->name;

  # The tests that are run are Test::More tests. Running them within a test
  # is a bit confusing. To simulate a proper test of the tests, need to reset
  # the Test::More framework.
  Test::More->builder->reset();
  my $result = $dbcheck->run;
  diag("Test enumeration reset by the datacheck object ($name)");

  is($result, 1, 'test fails');

  my ($started, $finished) = ($dbcheck->_started, $dbcheck->_finished);
  sleep(2);

  like($dbcheck->output, qr/# Subtest\: $name/m,    'tests ran as subtests');
  like($dbcheck->output, qr/^\s+not ok 1/m,         '1 subtest failed');
  like($dbcheck->output, qr/^\s+not ok 1 - $name/m, 'test failed');
  like($dbcheck->output, qr/^\s+1\.\.1/m,           'test ran with a plan');

  like($dbcheck->_started,  qr/^\d+$/, '_started attribute has numeric value');
  like($dbcheck->_finished, qr/^\d+$/, '_finished attribute has numeric value');
  is($dbcheck->_passed,     0,         '_passed attribute is false');

  # Now that we've run the test, we've got something to compare against
  # the database tables. However, because the test failed, we always
  # need to run it.
  is($dbcheck->check_history(),  undef, 'check_history method undefined');
  is($dbcheck->skip_datacheck(), undef, 'skip_datacheck method undefined');

  Test::More->builder->reset();
  $result = $dbcheck->run;
  diag("Test enumeration reset by the datacheck object ($name)");

  is($result, 1, 'test fails');

  like($dbcheck->output, qr/# Subtest\: $name/m,    'tests ran as subtests');
  like($dbcheck->output, qr/^\s+not ok 1/m,         '1 subtest failed');
  like($dbcheck->output, qr/^\s+not ok 1 - $name/m, 'test failed');
  like($dbcheck->output, qr/^\s+1\.\.1/m,           'test ran with a plan');

  cmp_ok($dbcheck->_started,  '>', $started,  '_started attribute changed when failed datacheck re-run');
  cmp_ok($dbcheck->_finished, '>', $finished, '_finished attribute changed when failed datacheck re-run');
  is($dbcheck->_passed,        0,             '_passed attribute remains false');
};

subtest 'DbCheck with non-matching db_type', sub {
  my $dbcheck = TestChecks::DbCheck_3->new(
    dba => $dba,
  );
  isa_ok($dbcheck, $module);

  my $name = $dbcheck->name;

  is_deeply($dbcheck->db_types, ['variation'], 'db_types attribute set correctly');

  my ($skip, $skip_reason) = $dbcheck->verify_db_type();
  is($skip, 1, 'db_types used to skip datacheck');
  is($skip_reason, "Database type 'core' is not relevant for this datacheck", 'Correct skip reason');

  ($skip, $skip_reason) = $dbcheck->skip_datacheck();
  is($skip, 1, 'db_types used to skip datacheck');
  is($skip_reason, "Database type 'core' is not relevant for this datacheck", 'Correct skip reason');
};

subtest 'DbCheck with db_type and tables', sub {
  my $dbcheck = TestChecks::DbCheck_4->new(
    dba => $dba,
  );
  isa_ok($dbcheck, $module);

  my $name = $dbcheck->name;

  is_deeply($dbcheck->db_types, ['core'],               'db_types attribute set correctly');
  is_deeply($dbcheck->tables,   ['gene', 'transcript'], 'tables attribute set correctly');

  is($dbcheck->verify_db_type(), undef, 'verify_db_type method undefined');

  # The tests that are run are Test::More tests. Running them within a test
  # is a bit confusing. To simulate a proper test of the tests, need to reset
  # the Test::More framework.
  Test::More->builder->reset();
  my $result = $dbcheck->run;
  diag("Test enumeration reset by the datacheck object ($name)");

  sleep(2);

  like($dbcheck->_started,  qr/^\d+$/, '_started attribute has numeric value');
  like($dbcheck->_finished, qr/^\d+$/, '_finished attribute has numeric value');
  is($dbcheck->_passed,     1,         '_passed attribute is true');

  # Now that we've run the test, we've got something to compare against
  # the database tables, 'gene' and 'transcript' in this case.
  my ($skip, undef) = $dbcheck->check_history();
  is($skip, 1, 'History used to skip datacheck after no table updates');

  Test::More->builder->reset();
  $result = $dbcheck->run;
  diag("Test enumeration reset by the datacheck object ($name)");

  sleep(2);

  # Force an update to the timestamp of a table that is _not_ linked to this datacheck.
  $dba->dbc->sql_helper->execute_update('ALTER TABLE exon ADD COLUMN test_col INT;');
  $dba->dbc->sql_helper->execute_update('ALTER TABLE exon DROP COLUMN test_col;');

  ($skip, undef) = $dbcheck->check_history();
  is($skip, 1, 'History used to skip datacheck after irrelevant table update');

  Test::More->builder->reset();
  $result = $dbcheck->run;
  diag("Test enumeration reset by the datacheck object ($name)");

  my $started = $dbcheck->_started;
  sleep(2);

  # Force an update to the timestamp of a table that is linked to this datacheck.
  $dba->dbc->sql_helper->execute_update('ALTER TABLE gene ADD COLUMN test_col INT;');
  $dba->dbc->sql_helper->execute_update('ALTER TABLE gene DROP COLUMN test_col;');

  ($skip, undef) = $dbcheck->check_history();
  is($skip, undef, 'History not used to skip datacheck after relevant table update');

  Test::More->builder->reset();
  $result = $dbcheck->run;
  diag("Test enumeration reset by the datacheck object ($name)");

  cmp_ok($dbcheck->_started, '>', $started, '_started attribute changed after relevant table update');
  like($dbcheck->_finished,  qr/^\d+$/,     '_finished attribute has numeric value after relevant table update');
  is($dbcheck->_passed,        1,           '_passed attribute is true');

  # Tell datacheck that it needs to run, even if tables haven't changed.
  $dbcheck->force(1);
  ($skip, undef) = $dbcheck->check_history();
  is($skip, undef, 'Datacheck forced to run when it would normally be skipped');
};

subtest 'DbCheck with skip_tests method defined', sub {
  my $dbcheck = TestChecks::DbCheck_5->new(
    dba => $dba,
  );
  isa_ok($dbcheck, $module);

  my $name = $dbcheck->name;

  my ($skip, $skip_reason) = $dbcheck->skip_tests();
  is($skip, undef, 'Do not skip if condition is not met');
  is($skip_reason, undef, 'No skip reason');

  ($skip, $skip_reason) = $dbcheck->skip_datacheck();
  is($skip, undef, 'Do not skip if condition is not met');
  is($skip_reason, undef, 'No skip reason');

  ($skip, $skip_reason) = $dbcheck->skip_tests('please');
  is($skip, 1, 'Skip if condition is not met');
  is($skip_reason, 'All good here, thank you', 'Correct skip reason');
};

subtest 'DbCheck with and without dba attribute', sub {
  my $dbcheck = TestChecks::DbCheck_1->new();
  isa_ok($dbcheck, $module);

  my $name = $dbcheck->name;

  throws_ok(
    sub { $dbcheck->run },
    qr/DBAdaptor must be set as 'dba' attribute/,
    'DbCheck->run fails without dba');

  is($dbcheck->_passed, undef, '_passed attribute is undefined');

  $dbcheck->dba($dba);

  is($dba->dbc->connected, undef, 'No DB connection');

  # The tests that are run are Test::More tests. Running them within a test
  # is a bit confusing. To simulate a proper test of the tests, need to reset
  # the Test::More framework.
  Test::More->builder->reset();
  my $result = $dbcheck->run;
  diag("Test enumeration reset by the datacheck object ($name)");

  is($dbcheck->_passed, 1, '_passed attribute is true');

  is($dba->dbc->connected, undef, 'No DB connection');
};

subtest 'Registry instantiation', sub {
  # We generally don't know what servers are available, in order to
  # test registry functionality. But we do know about one server,
  # the one with the $test_db, so extract that information.
  my %conf = %{$$testdb{conf}{$db_type}};
  my $driver = $conf{driver};
  my $host   = $conf{host};
  my $port   = $conf{port};
  my $user   = $conf{user};
  my $pass   = $conf{pass};

  my $registry_file = Path::Tiny->tempfile();
  my $registry_text = qq/
    use Bio::EnsEMBL::Registry;

    {
      Bio::EnsEMBL::Registry->load_registry_from_db(
        -driver => '$driver',
        -host   => '$host',
        -port   =>  $port,
        -user   => '$user',
        -pass   => '$pass',
      );
    }

    1;
  /;
  $registry_file->spew($registry_text);

  my $server_uri = "$driver://$user:$pass\@$host:$port/";

  my $check = TestChecks::DbCheck_1->new(
    dba => $dba,
  );

  throws_ok(
    sub { $check->registry },
    qr/Registry requires a 'registry_file' or 'server_uri' attribute/,
    'DbCheck->registry fails if a file or uri is not set');

  $check = TestChecks::DbCheck_1->new(
    dba        => $dba,
    server_uri => $server_uri,
  );

  # The registry object is a bit weird, the return value is a string,
  # so check that it actually is a working registry by using it.
  is($check->registry, 'Bio::EnsEMBL::Registry', 'registry attribute set via server_uri');
  my $species_list = $check->registry->get_all_species;
  ok(scalar(@$species_list), 'registry works when set via server_uri');

  $check = TestChecks::DbCheck_1->new(
    dba        => $dba,
    server_uri => $server_uri.$dba->dbc->dbname,
  );

  throws_ok(
    sub { $check->registry },
    qr/species and group parameters are required/,
    'DbCheck->registry fails if uri has dbname but no species attrib');

  $server_uri .=
	$dba->dbc->dbname.
	'?species='.$dba->species.
	';group='.$dba->group;

  $check = TestChecks::DbCheck_1->new(
    dba        => $dba,
    server_uri => $server_uri,
  );

  is($check->registry, 'Bio::EnsEMBL::Registry', 'registry attribute set via server_uri with dbname');
  $species_list = $check->registry->get_all_species;
  ok(scalar(@$species_list), 'registry works when set via server_uri with dbname');

  # Check both that registry_file works,
  # and that it has precedence over server_uri.
  $check = TestChecks::DbCheck_1->new(
    dba           => $dba,
    server_uri    => 'unconnectable rubbish',
    registry_file => $registry_file->stringify,
  );

  is($check->registry, 'Bio::EnsEMBL::Registry', 'registry attribute set via registry_file');
  $species_list = $check->registry->get_all_species;
  ok(scalar(@$species_list), 'registry works when set via registry_file');
};

subtest 'Fetch DBA from registry', sub {
  my %conf = %{$$testdb{conf}{$db_type}};
  my $driver = $conf{driver};
  my $host   = $conf{host};
  my $port   = $conf{port};
  my $user   = $conf{user};
  my $pass   = $conf{pass};

  my $server_uri = "$driver://$user:$pass\@$host:$port/";

  my $check = TestChecks::DbCheck_1->new(
    dba        => $dba,
    server_uri => $server_uri,
  );

  my $dba2 = $check->get_dba();

  isa_ok($dba2, $dba_type, 'Return value of "get_dba"');
  is($dba2->species, $dba->species, 'Species name matches');
  is($dba2->group,   $dba->group,   'Group matches');
};

subtest 'Set directory for data files', sub {
  my $check = TestChecks::DbCheck_1->new(
    data_file_path => '/data_files',
  );

  my $data_file_path = $check->data_file_path;

  is($data_file_path, '/data_files', 'Set data_file_path');
};

$species = 'collection';
$db_type = 'core';
$testdb  = Bio::EnsEMBL::Test::MultiTestDB->new($species, $test_db_dir);
$dba     = $testdb->get_DBAdaptor($db_type);
$dba->is_multispecies(1);

subtest 'DbCheck with collection database', sub {
  my $dbcheck = TestChecks::DbCheck_1->new(
    dba => $dba,
  );
  isa_ok($dbcheck, $module);

  my $name = $dbcheck->name;

  is($dbcheck->species, 'giardia_intestinalis', 'Species name correct for collection db');

  Test::More->builder->reset();
  my $result = $dbcheck->run;
  diag("Test enumeration reset by the datacheck object ($name)");

  is($result, 0, 'test passes');

  like($dbcheck->output, qr/\s*1\.\.3/, 'Tests run for three species');
  like($dbcheck->output, qr/Subtest: giardia_intestinalis/,     'Test run for first collection species');
  like($dbcheck->output, qr/Subtest: giardia_lamblia_p15/,      'Test run for second collection species');
  like($dbcheck->output, qr/Subtest: spironucleus_salmonicida/, 'Test run for third collection species');
};

subtest 'DbCheck with collection database, single species', sub {
  my $dbcheck = TestChecks::DbCheck_1->new(
    dba => $dba,
    dba_species_only => 1,
  );
  isa_ok($dbcheck, $module);

  my $name = $dbcheck->name;

  Test::More->builder->reset();
  my $result = $dbcheck->run;
  diag("Test enumeration reset by the datacheck object ($name)");

  is($result, 0, 'test passes');

  unlike($dbcheck->output, qr/\s*1\.\.3/, 'Tests not run for three species');
  like($dbcheck->output, qr/Subtest: DbCheck_1/, 'Test run for single species in collection');
};

subtest 'DbCheck with collection database, per_db', sub {
  my $dbcheck = TestChecks::DbCheck_4->new(
    dba => $dba,
  );
  isa_ok($dbcheck, $module);

  my $name = $dbcheck->name;

  Test::More->builder->reset();
  my $result = $dbcheck->run;
  diag("Test enumeration reset by the datacheck object ($name)");

  is($result, 0, 'test passes');

  unlike($dbcheck->output, qr/\s*1\.\.3/, 'Test not run for three species');
  like($dbcheck->output, qr/Subtest: DbCheck_4/, 'Test run for whole collection database');
};

done_testing();
