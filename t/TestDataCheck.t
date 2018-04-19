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

use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::Test::MultiTestDB;

use FindBin; FindBin::again();
use Test::More;

my $test_db_dir = $FindBin::Bin;

my $species  = 'drosophila_melanogaster';
my $db_type  = 'core';
my $dba_type = 'Bio::EnsEMBL::DBSQL::DBAdaptor';
my $testdb   = Bio::EnsEMBL::Test::MultiTestDB->new($species, $test_db_dir);
my $dba      = $testdb->get_DBAdaptor($db_type);

my $module = 'Bio::EnsEMBL::DataCheck::Test::DataCheck';

diag('Methods');
can_ok($module, qw(is_rows cmp_rows is_rows_zero is_rows_nonzero row_totals row_subtotals fk));

subtest 'Counting Database Rows', sub {
  my $sql_1 = 'SELECT COUNT(*) FROM gene';
  my $sql_2 = 'SELECT stable_id FROM gene';
  my $sql_3 = 'SELECT COUNT(*) FROM gene WHERE stable_id = "banana"';
  my $sql_4 = 'SELECT stable_id FROM gene WHERE stable_id = "banana"';

  is_rows($dba, $sql_1, 354, 'SQL statement with COUNT');
  is_rows($dba, $sql_2, 354, 'SQL statement without COUNT');
  is_rows($dba->dbc, $sql_1, 354, 'Use DBConnection instead of DBAdaptor');

  cmp_rows($dba, $sql_1, '>', 100, 'Greater than comparison');
  cmp_rows($dba, $sql_1, '!=', 25, 'Not equals comparison');

  is_rows_nonzero($dba, $sql_1, 'Non-zero count');

  is_rows_zero($dba, $sql_3, 'SQL statement with COUNT');
  is_rows_zero($dba, $sql_4, 'SQL statement without COUNT');
};

subtest 'Comparing Database Rows', sub {
  my $dba2 = $testdb->get_DBAdaptor($db_type);

  my $sql_1 = 'SELECT COUNT(*) FROM gene';
  my $sql_2 = 'SELECT biotype, COUNT(*) FROM gene GROUP BY biotype';

  row_totals($dba, $dba2, $sql_1, 1, 'Counts are the same');
  row_subtotals($dba, $dba2, $sql_2, 1, 'Biotype counts are the same');
};

done_testing();
