# Copyright [2018-2022] EMBL-European Bioinformatics Institute
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

use Bio::EnsEMBL::Utils::URI qw/parse_uri/;
use FindBin; FindBin::again();
use Test::Exception;
use Test::More;

use lib "$FindBin::Bin/TestChecks";
use DbCheck_1;

my $test_db_dir = $FindBin::Bin;

{
  # Need a test metadata db for retrieving the name of a previous
  # release's database. (Do it like this to prevent loading the
  # compara test db, which is also 'multi'.)
  my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('multi', $test_db_dir, 1);
  $multi->load_database('metadata');
  $multi->store_config();
  $multi->create_adaptors();
  my $metadata_dba = $multi->get_DBAdaptor('metadata');

  my $species = 'homo_sapiens';
  my %dba_types = (
    'core'      => 'Bio::EnsEMBL::DBSQL::DBAdaptor',
    'funcgen'   => 'Bio::EnsEMBL::Funcgen::DBSQL::DBAdaptor',
    'variation' => 'Bio::EnsEMBL::Variation::DBSQL::DBAdaptor',
  );
  my $testdb = Bio::EnsEMBL::Test::MultiTestDB->new($species, $test_db_dir);

  foreach my $db_type (sort keys %dba_types) {
    subtest "Fetch old DBA - $db_type", sub {
      my $dba      = $testdb->get_DBAdaptor($db_type);
      my $dba_type = $dba_types{$db_type};

      my $server_uri = get_server_uri($testdb, $db_type);

      my $check = TestChecks::DbCheck_1->new(
        dba            => $dba,
        server_uri     => [$server_uri],
        old_server_uri => [$server_uri.$dba->dbc->dbname],
      );
      my $old_dba = $check->get_old_dba();
      isa_ok($old_dba, $dba_type, 'Return value of "get_old_dba"');
      is($old_dba->species, "${species}_old", 'Species has "_old" suffix');

      $check = TestChecks::DbCheck_1->new(
        dba        => $dba,
        server_uri => [$server_uri],
      );
      throws_ok(
        sub { $check->get_old_dba },
        qr/Old server details must be set/,
        'Fail if old_server_uri is not set');

      $check = TestChecks::DbCheck_1->new(
        dba            => $dba,
        server_uri     => [$server_uri],
        old_server_uri => [$server_uri.'rhubarb_and_custard'],
      );
      throws_ok(
        sub { $check->get_old_dba },
        qr/Specified database does not exist/,
        'Fail if specified database does not exist');

      $check = TestChecks::DbCheck_1->new(
        dba            => $dba,
        server_uri     => [$server_uri],
        old_server_uri => [$server_uri.'95'],
      );
      $check->load_registry();
      $check->registry->add_DBAdaptor('multi', 'metadata', $metadata_dba);
      throws_ok(
        sub { $check->get_old_dba },
        qr/Database in metadata database does not exist/,
        'Fail if database from metadata database does not exist (1/2)');
      throws_ok(
        sub { $check->get_old_dba($species, $db_type) },
        qr/Database in metadata database does not exist/,
        'Fail if database from metadata database does not exist (2/2)');

      $old_dba = $check->get_old_dba('dinanthropoides_nivalis', $db_type);
      ok(! defined $old_dba, 'undef if no information in metadata database');
    }
  }

  foreach my $db_type (sort keys %dba_types) {  
    subtest "Fetch old DBA for given multiple old_server_uri  - $db_type", sub {
      my $dba      = $testdb->get_DBAdaptor($db_type);
      my $dba_type = $dba_types{$db_type};

      my $server_uri = get_server_uri($testdb, $db_type);

      my $check = TestChecks::DbCheck_1->new(
        dba            => $dba,
        server_uri     => [$server_uri],
        old_server_uri => [$server_uri.'95'],
      );
      $check->load_registry();
      $check->registry->add_DBAdaptor('multi', 'metadata', $metadata_dba);
      throws_ok(
        sub { $check->get_old_dba },
        qr/Database in metadata database does not exist/,
        'Fail if database from metadata database does not exist (1/2)');

      $check = TestChecks::DbCheck_1->new(
        dba            => $dba,
        server_uri     => [$server_uri],
        old_server_uri => [$server_uri.'95', $server_uri.'96', $server_uri.$dba->dbc->dbname],
      );
      my $old_dba = $check->get_old_dba();
      isa_ok($old_dba, $dba_type, 'Return value of "get_old_dba"');
      is($old_dba->species, "${species}_old", 'Species has "_old" suffix');
    }
  }

  subtest "Fetch old DBA - collection", sub {
    my $species  = 'collection';
    my $db_type  = 'core';
    my $testdb = Bio::EnsEMBL::Test::MultiTestDB->new($species, $test_db_dir);
    my $dba = $testdb->get_DBAdaptor($db_type);
    $dba->is_multispecies(1);
    my $dba_type = 'Bio::EnsEMBL::DBSQL::DBAdaptor';

    my $server_uri = get_server_uri($testdb, $db_type);

    my $check = TestChecks::DbCheck_1->new(
      dba            => $dba,
      server_uri     => [$server_uri],
      old_server_uri => [$server_uri.$dba->dbc->dbname],
    );
    my $old_dba = $check->get_old_dba();
    isa_ok($old_dba, $dba_type, 'Return value of "get_old_dba"');
    is($old_dba->species, 'giardia_intestinalis_old', 'Species has "_old" suffix');

    $check = TestChecks::DbCheck_1->new(
      dba            => $dba,
      server_uri     => [$server_uri],
      old_server_uri => [$server_uri.'95'],
    );
    $check->load_registry();
    $check->registry->add_DBAdaptor('multi', 'metadata', $metadata_dba);
    throws_ok(
      sub { $check->get_old_dba },
      qr/Database in metadata database does not exist/,
      'Fail if database from metadata database does not exist (1/2)');
    throws_ok(
      sub { $check->get_old_dba('giardia_intestinalis', $db_type) },
      qr/Database in metadata database does not exist/,
      'Fail if database from metadata database does not exist (2/2)');
  };
}

{
  subtest 'Fetch old DBA - compara', sub {
    my $species  = 'multi';
    my $db_type  = 'compara';
    my $testdb = Bio::EnsEMBL::Test::MultiTestDB->new($species, $test_db_dir, 1);
    $testdb->load_database($db_type);
    $testdb->store_config();
    $testdb->create_adaptors();
    my $dba = $testdb->get_DBAdaptor($db_type);
    my $dba_type = 'Bio::EnsEMBL::Compara::DBSQL::DBAdaptor';

    my $server_uri = get_server_uri($testdb, $db_type);

    my $check = TestChecks::DbCheck_1->new(
      dba            => $dba,
      server_uri     => [$server_uri],
      old_server_uri => [$server_uri.$dba->dbc->dbname],
    );
    my $old_dba = $check->get_old_dba();
    isa_ok($old_dba, $dba_type, 'Return value of "get_old_dba"');
    is($old_dba->species, "${species}_old", 'Species has "_old" suffix');

    $check = TestChecks::DbCheck_1->new(
      dba            => $dba,
      server_uri     => [$server_uri],
      old_server_uri => [$server_uri.'95'],
    );
    my $mca = $dba->get_adaptor("MetaContainer");
    my $uri = parse_uri($server_uri.'95');
    throws_ok(
      sub { $check->find_old_dbname('ensembl_compara_96', $mca, $species, $db_type, 95, $uri) },
      qr/Previous version of database does not exist/,
      'Fail if old database does not exist');
  };
}

sub get_server_uri {
  my ($testdb, $db_type) = @_;

  # Getting a proper 'old' server is a pain,
  # we just pretend that the test server is it.
  my %conf = %{$$testdb{conf}{$db_type}};
  my $driver = $conf{driver};
  my $host   = $conf{host};
  my $port   = $conf{port};
  my $user   = $conf{user};
  my $pass   = $conf{pass};

  my $server_uri = "$driver://$user:$pass\@$host:$port/";

  return $server_uri;
}

done_testing();
