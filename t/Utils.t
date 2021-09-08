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

use Bio::EnsEMBL::DataCheck::Utils qw(
  repo_location
  foreign_keys 
  sql_count
  array_diff
  hash_diff
  is_compara_ehive_db
  same_metavalue
  same_assembly
  same_geneset
);
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

subtest 'Foreign Keys', sub {
  my @db_types = qw(core funcgen variation compara); 

  foreach my $db_type (@db_types) {
    my ($foreign_keys, $failed_to_parse) = foreign_keys($db_type);
    ok(scalar(@$foreign_keys), "Retrieved $db_type db foreign keys");
    is(scalar(@{$$foreign_keys[0]}), 4, "Relationships have four elements");
    is(scalar(@$failed_to_parse), 0, "No $db_type db parsing failures");
  }

  throws_ok(
    sub { foreign_keys('ensembl-datacheck') },
    qr/file does not exist/, 'fail on invalid repository');
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

subtest 'Same metavalue check', sub {
  my $testdb_current = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens', $test_db_dir);
  my $dba_current = $testdb_current->get_DBAdaptor('core');
  my $testdb_old = Bio::EnsEMBL::Test::MultiTestDB->new('drosophila_melanogaster', $test_db_dir);
  my $dba_old = $testdb_old->get_DBAdaptor('core');

  $dba_current->dbc->db_handle->do("INSERT INTO meta ( meta_key, meta_value ) VALUES ( 'assembly.default_value_test', '12345' )");
  $dba_old->dbc->db_handle->do("INSERT INTO meta ( meta_key, meta_value ) VALUES ( 'assembly.default_value_test', '12345' )");

  my $mca = $dba_current->get_adaptor('MetaContainer');
  my $old_mca = $dba_old->get_adaptor('MetaContainer');
  
  my $same_metavalue_check = same_metavalue($mca, $old_mca, 'assembly.default_value_test');
  is($same_metavalue_check, 1, 'Correct comparison - both DBs have same value for the the meta key');
};

subtest 'Same metavalue check - negative', sub {
  my $testdb_current = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens', $test_db_dir);
  my $dba_current = $testdb_current->get_DBAdaptor('core');
  my $testdb_old = Bio::EnsEMBL::Test::MultiTestDB->new('drosophila_melanogaster', $test_db_dir);
  my $dba_old = $testdb_old->get_DBAdaptor('core');

  $dba_current->dbc->db_handle->do("INSERT INTO meta ( meta_key, meta_value ) VALUES ( 'assembly.default_value_test2', '67890' )");
  $dba_old->dbc->db_handle->do("INSERT INTO meta ( meta_key, meta_value ) VALUES ( 'assembly.default_value_test2', '0000' )");

  my $mca = $dba_current->get_adaptor('MetaContainer');
  my $old_mca = $dba_old->get_adaptor('MetaContainer');
  
  my $same_metavalue_check = same_metavalue($mca, $old_mca, 'assembly.default_value_test2');
  is($same_metavalue_check, 0, 'Correct comparison - DBs have different values for the the meta key');
};

subtest 'Same metavalue check - no key', sub {
  my $testdb_current = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens', $test_db_dir);
  my $dba_current = $testdb_current->get_DBAdaptor('core');
  my $testdb_old = Bio::EnsEMBL::Test::MultiTestDB->new('drosophila_melanogaster', $test_db_dir);
  my $dba_old = $testdb_old->get_DBAdaptor('core');

  my $mca = $dba_current->get_adaptor('MetaContainer');
  my $old_mca = $dba_old->get_adaptor('MetaContainer');
  
  my $same_metavalue_check = same_metavalue($mca, $old_mca, 'nonexistent.key');
  is($same_metavalue_check, 0, 'Correct comparison - Key does not exists');
};

subtest 'Same assembly check', sub {
  my $testdb_current = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens', $test_db_dir);
  my $dba_current = $testdb_current->get_DBAdaptor('core');
  my $testdb_old = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens', $test_db_dir);
  my $dba_old = $testdb_old->get_DBAdaptor('core');

  my $mca = $dba_current->get_adaptor('MetaContainer');
  my $old_mca = $dba_old->get_adaptor('MetaContainer');
  
  my $same_assembly_check = same_assembly($mca, $old_mca);
  is($same_assembly_check, 1, 'Correct comparison - DBs have same assembly');
};

subtest 'Same geneset check', sub {
  my $testdb_current = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens', $test_db_dir);
  my $dba_current = $testdb_current->get_DBAdaptor('core');
  my $testdb_old = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens', $test_db_dir);
  my $dba_old = $testdb_old->get_DBAdaptor('core');

  my $mca = $dba_current->get_adaptor('MetaContainer');
  my $old_mca = $dba_old->get_adaptor('MetaContainer');
  
  my $same_geneset_check = same_geneset($mca, $old_mca);
  is($same_geneset_check, 1, 'Correct comparison - DBs have same geneset');
};

done_testing();
