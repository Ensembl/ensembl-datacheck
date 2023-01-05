# Copyright [2018-2023] EMBL-European Bioinformatics Institute
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

my $test_db_dir = $FindBin::Bin;
my $dba_type    = 'Bio::EnsEMBL::DBSQL::DBAdaptor';

my $species = 'homo_sapiens';
my $testdb  = Bio::EnsEMBL::Test::MultiTestDB->new($species, $test_db_dir);
my $multi   = Bio::EnsEMBL::Test::MultiTestDB->new('multi', $test_db_dir, 1);

my $module = 'Bio::EnsEMBL::DataCheck::DbCheck';

# Need a test metadata db to resolve the required core database name.
# (Do it like this to prevent loading the  compara test db,
# which is also 'multi'.)
$multi->load_database('metadata');
$multi->store_config();
$multi->create_adaptors();
my $metadata_dba = $multi->get_DBAdaptor('metadata');

$multi->load_database('compara');
$multi->store_config();
$multi->create_adaptors();
my $compara_dba = $multi->get_DBAdaptor('compara');

my $core_dba = $testdb->get_DBAdaptor('core');
my $funcgen_dba = $testdb->get_DBAdaptor('funcgen');
my $variation_dba = $testdb->get_DBAdaptor('variation');

my %dbas = (
  compara   => $compara_dba,
  funcgen   => $funcgen_dba,
  variation => $variation_dba
);

foreach my $db_type (keys %dbas) {
  my $dba = $dbas{$db_type};

  subtest "DbCheck with $db_type database", sub {
    my $dbcheck = TestChecks::DbCheck_1->new(
      dba => $dba,
    );
    isa_ok($dbcheck, $module);

    my $name = $dbcheck->name;

    Test::More->builder->reset();
    my $result = $dbcheck->run;
    diag("Test enumeration reset by the datacheck object ($name)");

    is($result, 0, 'test passes');

    like($dbcheck->output, qr/^\s+ok 1 - $name/m,  'test ran successfully');
  };
}

subtest 'Fetch DNA DBA from registry', sub {
  # We generally don't know what servers are available, in order to
  # test registry functionality. But we do know about one server,
  # the one with the $test_db, so extract that information.
  my %conf = %{$$testdb{conf}{'core'}};
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

  my $check = TestChecks::DbCheck_1->new(
    dba           => $variation_dba,
    registry_file => $registry_file->stringify,
  );

  # The test databases are added to the registry via MultiTestDB; but
  # the datacheck code removes them as part of it's standard monkeying
  # around, and their names are such that they are not picked up when
  # the registry is subsequently loaded. So, we need to pre-load the
  # registry, then add them back. Phew.
  my $reg = $check->load_registry();
  $reg->add_DBAdaptor($species, 'core', $core_dba);
  $reg->add_DBAdaptor($species, 'variation', $variation_dba);

  my $dna_dba = $check->get_dna_dba();

  isa_ok($dna_dba, $dba_type, 'Return value of "get_dna_dba"');
  is($dna_dba->species, $species, 'Species name matches');
  is($dna_dba->group,   'core',   'Group matches');
};

subtest 'Fetch DNA DBA from server_uri', sub {
  my %conf = %{$$testdb{conf}{'core'}};
  my $driver = $conf{driver};
  my $host   = $conf{host};
  my $port   = $conf{port};
  my $user   = $conf{user};
  my $pass   = $conf{pass};

  my $server_uri = "$driver://$user:$pass\@$host:$port/";

  my $check = TestChecks::DbCheck_1->new(
    dba        => $variation_dba,
    server_uri => [$server_uri],
  );

  # The test databases are added to the registry via MultiTestDB; but
  # the datacheck code removes them as part of it's standard monkeying
  # around, and their names are such that they are not picked up when
  # the registry is subsequently loaded. So, we need to pre-load the
  # registry, then add them back. Phew.
  my $reg = $check->load_registry();
  $reg->add_DBAdaptor($species, 'core', $core_dba);
  $reg->add_DBAdaptor($species, 'variation', $variation_dba);

  my $dna_dba = $check->get_dna_dba();

  isa_ok($dna_dba, $dba_type, 'Return value of "get_dna_dba"');
  is($dna_dba->species, $species, 'Species name matches');
  is($dna_dba->group,   'core',   'Group matches');
};

subtest 'Fetch DNA DBA from server_uri, with registry (variation)', sub {
  my %conf = %{$$testdb{conf}{'core'}};
  my $driver = $conf{driver};
  my $host   = $conf{host};
  my $port   = $conf{port};
  my $user   = $conf{user};
  my $pass   = $conf{pass};

  # Empty registry, to test if we use server_uri correctly.
  my $registry_file = Path::Tiny->tempfile();
  my $registry_text = qq/
    use Bio::EnsEMBL::Registry;

    1;
  /;
  $registry_file->spew($registry_text);

  my $server_uri = "$driver://$user:$pass\@$host:$port/";
  my $core_dbname = $core_dba->dbc->dbname;

  my $check = TestChecks::DbCheck_1->new(
    dba           => $variation_dba,
    registry_file => $registry_file->stringify,
    server_uri    => [$server_uri.$core_dbname],
  );

  # The test databases are added to the registry via MultiTestDB; but
  # the datacheck code removes them as part of it's standard monkeying
  # around, and their names are such that they are not picked up when
  # the registry is subsequently loaded. So, we need to pre-load the
  # registry, then add them back. Phew.
  $check->load_registry();
  my $reg = $check->load_registry();
  $reg->add_DBAdaptor($species, 'core', $core_dba);
  $reg->add_DBAdaptor($species, 'variation', $variation_dba);

  my $dna_dba = $check->get_dna_dba();

  isa_ok($dna_dba, $dba_type, 'Return value of "get_dna_dba", with dbname');
  is($dna_dba->species, $species, 'Species name matches');
  is($dna_dba->group,   'core',   'Group matches');

  $check = TestChecks::DbCheck_1->new(
    dba           => $variation_dba,
    registry_file => $registry_file->stringify,
    server_uri    => [$server_uri],
  );

  # We also need to add the metadata db in this case, so that
  # we can determine the name of the ancillary db.
  $check->load_registry();
  $reg = $check->load_registry();
  $reg->add_DBAdaptor($species, 'core', $core_dba);
  $reg->add_DBAdaptor('multi', 'metadata', $metadata_dba);
  $reg->add_DBAdaptor($species, 'variation', $variation_dba);

  $dna_dba = $check->get_dna_dba();

  isa_ok($dna_dba, $dba_type, 'Return value of "get_dna_dba", without dbname');
  is($dna_dba->species, $species, 'Species name matches');
  is($dna_dba->group,   'core',   'Group matches');
};

subtest 'Fetch DNA DBA from server_uri, with registry (compara)', sub {
  my %conf = %{$$testdb{conf}{'core'}};
  my $driver = $conf{driver};
  my $host   = $conf{host};
  my $port   = $conf{port};
  my $user   = $conf{user};
  my $pass   = $conf{pass};

  # Empty registry, to test if we use server_uri correctly.
  my $registry_file = Path::Tiny->tempfile();
  my $registry_text = qq/
    use Bio::EnsEMBL::Registry;

    1;
  /;
  $registry_file->spew($registry_text);

  my $server_uri = "$driver://$user:$pass\@$host:$port/";
  my $core_dbname = $core_dba->dbc->dbname;

  my $check = TestChecks::DbCheck_1->new(
    dba           => $compara_dba,
    registry_file => $registry_file->stringify,
    server_uri    => [$server_uri.$core_dbname],
  );

  # The test databases are added to the registry via MultiTestDB; but
  # the datacheck code removes them as part of it's standard monkeying
  # around, and their names are such that they are not picked up when
  # the registry is subsequently loaded. So, we need to pre-load the
  # registry, then add them back. Phew.
  $check->load_registry();
  my $reg = $check->load_registry();
  $reg->add_DBAdaptor($species, 'core', $core_dba);
  $reg->add_DBAdaptor('multi', 'compara', $compara_dba);

  my $genome_dba = $check->get_dba($species, 'core');

  isa_ok($genome_dba, $dba_type, 'Return value of "get_dba", with dbname');
  is($genome_dba->species, $species, 'Species name matches');
  is($genome_dba->group,   'core',   'Group matches');

  $check = TestChecks::DbCheck_1->new(
    dba           => $compara_dba,
    registry_file => $registry_file->stringify,
    server_uri    => [$server_uri],
  );

  # We also need to add the metadata db in this case, so that
  # we can determine the name of the ancillary db.
  $check->load_registry();
  $reg = $check->load_registry();
  $reg->add_DBAdaptor($species, 'core', $core_dba);
  $reg->add_DBAdaptor('multi', 'metadata', $metadata_dba);
  $reg->add_DBAdaptor('multi', 'compara', $compara_dba);

  $genome_dba = $check->get_dba($species, 'core');

  isa_ok($genome_dba, $dba_type, 'Return value of "get_dba", without dbname');
  is($genome_dba->species, $species, 'Species name matches');
  is($genome_dba->group,   'core',   'Group matches');
};

subtest 'Fetch variation DBA from server_uri, with registry', sub {
  my %conf = %{$$testdb{conf}{'core'}};
  my $driver = $conf{driver};
  my $host   = $conf{host};
  my $port   = $conf{port};
  my $user   = $conf{user};
  my $pass   = $conf{pass};

  # Empty registry, to test if we use server_uri correctly.
  my $registry_file = Path::Tiny->tempfile();
  my $registry_text = qq/
    use Bio::EnsEMBL::Registry;

    1;
  /;
  $registry_file->spew($registry_text);

  my $server_uri = "$driver://$user:$pass\@$host:$port/";

  my $check = TestChecks::DbCheck_1->new(
    dba           => $core_dba,
    registry_file => $registry_file->stringify,
    server_uri    => [$server_uri],
  );

  # We also need to add the metadata db in this case, so that
  # we can determine the name of the ancillary db.
  $check->load_registry();
  my $reg = $check->load_registry();
  $reg->add_DBAdaptor($species, 'core', $core_dba);
  $reg->add_DBAdaptor('multi', 'metadata', $metadata_dba);
  $reg->add_DBAdaptor($species, 'variation', $variation_dba);

  my $var_dba = $check->get_dba($species, 'variation');

  isa_ok($var_dba, 'Bio::EnsEMBL::Variation::DBSQL::DBAdaptor', 'Return value of "get_dba"');
  is($var_dba->species, $species, 'Species name matches');
  is($var_dba->group,   'variation',   'Group matches');
};

subtest '(Fail to) fetch core-like db from server_uri', sub {
  my %conf = %{$$testdb{conf}{'core'}};
  my $driver = $conf{driver};
  my $host   = $conf{host};
  my $port   = $conf{port};
  my $user   = $conf{user};
  my $pass   = $conf{pass};

  # Empty registry, to test if we use server_uri correctly.
  my $registry_file = Path::Tiny->tempfile();
  my $registry_text = qq/
    use Bio::EnsEMBL::Registry;

    1;
  /;
  $registry_file->spew($registry_text);

  my $server_uri = "$driver://$user:$pass\@$host:$port/";

  my $check = TestChecks::DbCheck_1->new(
    dba           => $core_dba,
    registry_file => $registry_file->stringify,
    server_uri    => [$server_uri],
  );

  # We also need to add the metadata db in this case, so that
  # we can determine the name of the ancillary db.
  $check->load_registry();
  my $reg = $check->load_registry();
  $reg->add_DBAdaptor($species, 'core', $core_dba);
  $reg->add_DBAdaptor('multi', 'metadata', $metadata_dba);

  my $of_dba = $check->get_dba($species, 'otherfeatures');

  ok(!defined $of_dba, 'Return undef if ancillary db not found');
};

done_testing();
