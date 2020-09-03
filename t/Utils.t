# Copyright [2018-2020] EMBL-European Bioinformatics Institute
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

use Bio::EnsEMBL::DataCheck::Utils qw( repo_location sql_count array_diff hash_diff is_compara_ehive_db );
use Bio::EnsEMBL::Test::MultiTestDB;

use FindBin; FindBin::again();
use Test::Exception;
use Test::More;

my $test_db_dir = $FindBin::Bin;
my @species     = qw(collection drosophila_melanogaster homo_sapiens);
my $db_type     = 'core';
my $dba_type    = 'Bio::EnsEMBL::DBSQL::DBAdaptor';

subtest 'Repository Location', sub {
  my $repo = repo_location('ensembl-datacheck');
  like($repo, qr!/ensembl-datacheck$!, 'Found repository with repo name');

  $repo = repo_location('core');
  like($repo, qr!/ensembl$!, 'Found repository with "core" db_type');

  $repo = repo_location('otherfeatures');
  like($repo, qr!/ensembl$!, 'Found repository with "otherfeatures" db_type');

  $repo = repo_location('variation');
  like($repo, qr!/ensembl-variation$!, 'Found repository with "variation" db_type');

  throws_ok(
    sub { repo_location('ensembl-bananas') },
    qr/was not found/, 'non-existent repository not located');
};

foreach my $species (@species) {
  my $testdb = Bio::EnsEMBL::Test::MultiTestDB->new($species, $test_db_dir);
  my $dba    = $testdb->get_DBAdaptor($db_type);

  subtest 'Count Database Rows', sub {
    my $sql_1 = 'SELECT COUNT(*) FROM gene';
    my $sql_2 = 'SELECT * FROM gene';
    my $sql_3 = 'SELECT * FROM gene WHERE gene_id > ?';

    my $sql_count_1 = sql_count($dba, $sql_1);
    my $sql_count_2 = sql_count($dba, $sql_2);
    my $sql_count_3 = sql_count($dba, $sql_3, 0);

    like($sql_count_1, qr/^\d+$/, 'With COUNT');
    like($sql_count_2, qr/^\d+$/, 'Without COUNT');
    is($sql_count_1, $sql_count_2, 'Counts match');
    like($sql_count_3, qr/^\d+$/, 'With parameters');
  };
}

subtest 'Array diff', sub {
  my @primates  = ('loris', 'siamang', 'bonobo');
  my @nocturnal = ('loris', 'vampire bat');

  my $diff = array_diff(\@primates, \@nocturnal);
  is_deeply($$diff{'In first set only'},  ['bonobo', 'siamang'], 'First set only');
  is_deeply($$diff{'In second set only'}, ['vampire bat'],       'Second set only');

  $diff = array_diff(\@primates, \@nocturnal, 'primates', 'nocturnal');
  is_deeply($$diff{'In primates only'},  ['bonobo', 'siamang'], 'Named first set');
  is_deeply($$diff{'In nocturnal only'}, ['vampire bat'],       'Named second set');
};

subtest 'Hash diff', sub {
  my %primate_names   = ('loris' => 'charles', 'siamang' => 'elizabeth', 'potto' => 'arthur');
  my %nocturnal_names = ('loris' => 'oliver', 'potto' => 'arthur', 'vampire bat' => 'harriet');

  my $diff = hash_diff(\%primate_names, \%nocturnal_names);
  is_deeply($$diff{'In first set only'},  {'siamang' => 'elizabeth'},          'First set only');
  is_deeply($$diff{'In second set only'}, {'vampire bat' => 'harriet'},        'Second set only');
  is_deeply($$diff{'Different values'},   {'loris' => ['charles', 'oliver']} , 'Different values');

  $diff = hash_diff(\%primate_names, \%nocturnal_names, 'primates', 'nocturnal');
  is_deeply($$diff{'In primates only'},  {'siamang' => 'elizabeth'},   'Named first set');
  is_deeply($$diff{'In nocturnal only'}, {'vampire bat' => 'harriet'}, 'Named second set');
};

subtest 'Compara e-hive check', sub {
  my $testdb = Bio::EnsEMBL::Test::MultiTestDB->new('multi');
  my $dba    = $testdb->get_DBAdaptor('metadata');

  my $ehive_check = is_compara_ehive_db($dba);
  is($ehive_check, 0, 'Correct assignment - not an ehive db');
  $dba->dbc->db_handle->do("CREATE TABLE job ( column1 int )");
  $ehive_check    = is_compara_ehive_db($dba);
  is($ehive_check, 1, 'Correct assignment - is an ehive db');
};

done_testing();
