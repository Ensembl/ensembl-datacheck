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

use Bio::EnsEMBL::DataCheck::Utils qw( repo_location sql_count );
use Bio::EnsEMBL::Test::MultiTestDB;

use FindBin; FindBin::again();
use Test::Exception;
use Test::More;

my $test_db_dir = $FindBin::Bin;

my $species  = 'drosophila_melanogaster';
my $db_type  = 'core';
my $dba_type = 'Bio::EnsEMBL::DBSQL::DBAdaptor';
my $testdb   = Bio::EnsEMBL::Test::MultiTestDB->new($species, $test_db_dir);
my $dba      = $testdb->get_DBAdaptor($db_type);

subtest 'Repository Location', sub {
  my $repo = repo_location('ensembl-datacheck');

  like($repo, qr!/ensembl-datacheck$!, 'valid repository located');

  throws_ok(
    sub { repo_location('ensembl-bananas') },
    qr/was not found/, 'non-existent repository not located');
};

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

done_testing();
