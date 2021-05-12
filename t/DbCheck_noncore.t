# Copyright [2018-2021] EMBL-European Bioinformatics Institute
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
use Test::Exception;
use Test::More;

use lib "$FindBin::Bin/TestChecks";
use DbCheck_1;

my $test_db_dir = $FindBin::Bin;
my $dba_type    = 'Bio::EnsEMBL::DBSQL::DBAdaptor';

my $species  = 'homo_sapiens';
my @db_types = ('funcgen', 'variation');
my $testdb   = Bio::EnsEMBL::Test::MultiTestDB->new($species, $test_db_dir);

my $module = 'Bio::EnsEMBL::DataCheck::DbCheck';

foreach my $db_type (@db_types) {
  my $dba = $testdb->get_DBAdaptor($db_type);

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
  my $dba = $testdb->get_DBAdaptor('variation');

  my %conf = %{$$testdb{conf}{'core'}};
  my $driver = $conf{driver};
  my $host   = $conf{host};
  my $port   = $conf{port};
  my $user   = $conf{user};
  my $pass   = $conf{pass};

  my $server_uri = "$driver://$user:$pass\@$host:$port/";

  my $check = TestChecks::DbCheck_1->new(
    dba        => $dba,
    server_uri => [$server_uri],
  );

  # The test databases are added to the registry via MultiTestDB; but
  # the datacheck code removes them as part of it's standard monkeying
  # around, and their names are such that they are not picked up when
  # the registry is subsequently loaded. So, we need to pre-load the
  # registry, then add them in via another call to MultiTestDB. Phew.
  $check->load_registry();
  $testdb = Bio::EnsEMBL::Test::MultiTestDB->new($species, $test_db_dir);
  
  my $dna_dba = $check->get_dna_dba();

  isa_ok($dna_dba, $dba_type, 'Return value of "get_dna_dba"');
  is($dna_dba->species, $species, 'Species name matches');
  is($dna_dba->group,   'core',   'Group matches');

  $server_uri .= $dba->dbc->dbname."?species=$species;group=variation";
  $check = TestChecks::DbCheck_1->new(
    dba        => $dba,
    server_uri => [$server_uri],
  );
};

done_testing();
