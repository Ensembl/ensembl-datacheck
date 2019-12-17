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

my $species = 'drosophila';
my $db_type = 'core';
my $testdb  = Bio::EnsEMBL::Test::MultiTestDB->new($species, $test_db_dir);

my $dba     = $testdb->get_DBAdaptor($db_type);

# Note that you cannot, by design, create a DbCheck object; datachecks
# must inherit from it and define mandatory, read-only parameters that
# are specific to that particular datacheck. So there's a limited amount
# of testing that we can do on the base class, the functionality is
# tested on a subclass.

my $module = 'Bio::EnsEMBL::DataCheck::DbCheck';

subtest 'Fetch old DBA', sub {
  # Getting a proper 'old' server is a pain,
  # we just pretend that the test server is it.
  my %conf = %{$$testdb{conf}{$db_type}};
  my $driver = $conf{driver};
  my $host   = $conf{host};
  my $port   = $conf{port};
  my $user   = $conf{user};
  my $pass   = $conf{pass};

  my $server_uri = "$driver://$user:$pass\@$host:$port/";

  # Need a test metadata db for retrieving the name of
  # a previous release's database.
  my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi', $test_db_dir);
  my $metadata_dba = $multi->get_DBAdaptor('metadata');

  my $check = TestChecks::DbCheck_1->new(
    dba            => $dba,
    server_uri     => $server_uri,
    old_server_uri => $server_uri.$dba->dbc->dbname,
  );

  # The test databases are added to the registry via MultiTestDB; but
  # the datacheck code removes them as part of it's standard monkeying
  # around, and their names are such that they are not picked up when
  # the registry is subsequently loaded. So, we need to pre-load the
  # registry, then add the metadata DBA back.
  $check->load_registry();
  $check->registry->add_DBAdaptor('multi', 'metadata', $metadata_dba);

  my $old_dba = $check->get_old_dba();

  isa_ok($old_dba, $dba_type, 'Return value of "get_old_dba"');
  is($old_dba->species, "${species}_old", 'Species has "_old" suffix');

  $check = TestChecks::DbCheck_1->new(
    dba        => $dba,
    server_uri => $server_uri,
  );
  throws_ok(
    sub { $check->get_old_dba },
    qr/Old server details must be set/,
    'Fail if old_server_uri is not set');

  $check = TestChecks::DbCheck_1->new(
    dba            => $dba,
    server_uri     => $server_uri,
    old_server_uri => $server_uri,
  );

  throws_ok(
    sub { $check->get_old_dba },
    qr/No metadata database found in the registry/,
    'Fail if metadata database does not exist');

  $check = TestChecks::DbCheck_1->new(
    dba            => $dba,
    server_uri     => $server_uri,
    old_server_uri => $server_uri.'rhubarb_and_custard',
  );

  throws_ok(
    sub { $check->get_old_dba },
    qr/Specified database does not exist/,
    'Fail if specified database does not exist');

  $check = TestChecks::DbCheck_1->new(
    dba            => $dba,
    server_uri     => $server_uri,
    old_server_uri => $server_uri.'95',
  );

  $check->load_registry();
  $check->registry->add_DBAdaptor('multi', 'metadata', $metadata_dba);

  throws_ok(
    sub { $check->get_old_dba },
    qr/Database in metadata database does not exist/,
    'Fail if database from metadata database does not exist (1/2)');
    
  throws_ok(
    sub { $check->get_old_dba('strigamia_maritima', 'core') },
    qr/Database in metadata database does not exist/,
    'Fail if database from metadata database does not exist (2/2)');

  $old_dba = $check->get_old_dba('dinanthropoides_nivalis', 'core');
  ok(! defined $old_dba, 'undef if no information in metadata database');
};

done_testing();
