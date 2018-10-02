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

# Quis custodiet ipsos custodes?
use Test::Tester;

use Bio::EnsEMBL::DataCheck::Test::DataCheck;
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

my $module = 'Bio::EnsEMBL::DataCheck::Test::DataCheck';

diag('Methods');
can_ok($module, qw(is_rows cmp_rows is_rows_zero is_rows_nonzero row_totals row_subtotals fk));

subtest 'Counting Database Rows', sub {
  my $sql_1 = 'SELECT COUNT(*) FROM gene';
  my $sql_2 = 'SELECT stable_id FROM gene';
  my $sql_3 = 'SELECT COUNT(*) FROM gene WHERE stable_id = "banana"';
  my $sql_4 = 'SELECT stable_id FROM gene WHERE stable_id = "banana"';
  
  subtest 'is_rows', sub {
    check_tests(
      sub {
        is_rows($dba, $sql_1, 354, 'pass: SQL statement with COUNT');
        is_rows($dba, $sql_1, 355, 'fail: SQL statement with COUNT');
        is_rows($dba, $sql_2, 354, 'pass: SQL statement without COUNT');
        is_rows($dba, $sql_2, 355, 'fail: SQL statement without COUNT');
        is_rows($dba->dbc, $sql_1, 354, 'pass: Use DBConnection instead of DBAdaptor');
        is_rows($dba->dbc, $sql_1, 355, 'fail: Use DBConnection instead of DBAdaptor');
      },
      [
        { ok => 1, depth => undef },
        { ok => 0, depth => undef },
        { ok => 1, depth => undef },
        { ok => 0, depth => undef },
        { ok => 1, depth => undef },
        { ok => 0, depth => undef },
      ],
      'is_rows method'
    );
  };

  subtest 'cmp_rows', sub {
    check_tests(
      sub {
        cmp_rows($dba, $sql_1, '>',  100, 'pass: Greater than comparison');
        cmp_rows($dba, $sql_1, '>',  500, 'fail: Greater than comparison');
        cmp_rows($dba, $sql_1, '!=',  25, 'pass: Not equals comparison');
        cmp_rows($dba, $sql_1, '!=', 354, 'fail: Not equals comparison');
      },
      [
        { ok => 1, depth => undef },
        { ok => 0, depth => undef },
        { ok => 1, depth => undef },
        { ok => 0, depth => undef },
      ],
      'cmp_rows method'
    );
  };

  subtest 'is_rows_nonzero', sub {
    check_tests(
      sub {
        is_rows_nonzero($dba, $sql_1, 'pass: Non-zero count');
        is_rows_nonzero($dba, $sql_3, 'fail: Non-zero count');
      },
      [
        { ok => 1, depth => undef },
        { ok => 0, depth => undef },
      ],
      'is_rows_nonzero method'
    );
  };

  subtest 'is_rows_zero', sub {
    check_tests(
      sub {
        is_rows_zero($dba, $sql_3, 'pass: SQL statement with COUNT');
        is_rows_zero($dba, $sql_1, 'fail: SQL statement with COUNT');
        is_rows_zero($dba, $sql_4, 'pass: SQL statement without COUNT');
        is_rows_zero($dba, $sql_2, 'fail: SQL statement without COUNT');
      },
      [
        { ok => 1, depth => undef },
        { ok => 0, depth => undef },
        { ok => 1, depth => undef },
        { ok => 0, depth => undef },
      ],
      'is_rows_zero method'
    );
  };
};

subtest 'Comparing Database Rows', sub {
  my $sql_1 = 'SELECT stable_id FROM gene';
  my $sql_2 = 'SELECT stable_id FROM gene LIMIT 250';
  my $sql_3 = 'SELECT biotype, COUNT(*) FROM gene GROUP BY biotype';
  my $sql_4 = 'SELECT biotype, COUNT(*) FROM gene WHERE biotype <> "protein_coding" GROUP BY biotype';
  my $sql_5 = 'SELECT COUNT(*) FROM gene';

  subtest 'row_totals', sub {
    check_tests(
      sub {
        row_totals($dba, undef, $sql_1, $sql_1, 1, 'pass: Exact row totals');
        row_totals($dba, undef, $sql_1, $sql_2, 1, 'fail: Exact row totals');
        row_totals($dba, undef, $sql_1, $sql_2, 0.5, 'pass: Row totals with min_proportion');
        row_totals($dba, undef, $sql_1, $sql_2, 0.9, 'pass: Row totals with min_proportion');
        row_totals($dba, undef, $sql_2, $sql_1, 0.5, 'pass: Row totals with min_proportion');
        row_totals($dba, undef, $sql_2, $sql_1, 0.9, 'fail: Row totals with min_proportion');
      },
      [
        { ok => 1, depth => undef },
        { ok => 0, depth => undef },
        { ok => 1, depth => undef },
        { ok => 1, depth => undef },
        { ok => 1, depth => undef },
        { ok => 0, depth => undef },
      ],
      'row_totals method'
    );
  };

  subtest 'row_subtotals', sub {
    check_tests(
      sub {
        row_subtotals($dba, undef, $sql_3, $sql_3, 1, 'pass: Row subtotals identical');
        row_subtotals($dba, undef, $sql_3, $sql_4, 1, 'pass: Row subtotals asymmetry');
        row_subtotals($dba, undef, $sql_4, $sql_3, 1, 'fail: Row subtotals asymmetry');
        row_subtotals($dba, undef, $sql_3, $sql_4, 0,   'pass: Row subtotals with min_proportion');
        row_subtotals($dba, undef, $sql_3, $sql_4, 0.5, 'pass: Row subtotals with min_proportion');
        row_subtotals($dba, undef, $sql_4, $sql_3, 0,   'pass: Row subtotals with min_proportion');
        row_subtotals($dba, undef, $sql_4, $sql_3, 0.5, 'fail: Row subtotals with min_proportion');
      },
      [
        { ok => 1, depth => undef },
        { ok => 1, depth => undef },
        { ok => 0, depth => undef },
        { ok => 1, depth => undef },
        { ok => 1, depth => undef },
        { ok => 1, depth => undef },
        { ok => 0, depth => undef },
      ],
      'row_subtotals method'
    );

    throws_ok(
      sub { row_subtotals($dba, undef, $sql_5, $sql_3) },
      qr/Invalid SQL statement for subtotals/, 'SQL statement format');

    throws_ok(
      sub { row_subtotals($dba, undef, $sql_3, $sql_5) },
      qr/Invalid SQL statement for subtotals/, 'SQL statement format');
  };
};

subtest 'Foreign Keys', sub {
  my $table_1 = 'transcript';
  my $table_2 = 'gene';
  my $table_3 = 'object_xref';
  my $col     = 'gene_id';

  subtest 'fk fine', sub {
    check_tests(
      sub {
        fk($dba, $table_1, $col, $table_2);
        fk($dba, $table_2, $col, $table_1, $col, undef, 'pass: transcript.gene_id => gene.gene_id');
        fk($dba, $table_3, 'ensembl_id', $table_2, $col, 'ensembl_object_type = "Gene"', 'pass: additional constraint');
      },
      [
        { ok => 1, depth => undef },
        { ok => 1, depth => undef },
        { ok => 1, depth => undef },
      ],
      'fk method'
    );
  };

  my $sql_break = qq/
	UPDATE gene SET gene_id = gene_id + 1
	WHERE gene_id IN (SELECT MAX(gene_id) FROM transcript)
  /;
  $dba->dbc->sql_helper->execute_update($sql_break);

  subtest 'fk broken', sub {
    check_tests(
      sub {
        fk($dba, $table_1, $col, $table_2, undef, undef, 'fail: gene.gene_id => transcript.gene_id');
        fk($dba, $table_2, $col, $table_1, $col, undef, 'fail: transcript.gene_id => gene.gene_id');
        fk($dba, $table_3, 'ensembl_id', $table_2, $col, 'ensembl_object_type = "Gene"', 'fail: additional constraint');
      },
      [
        { ok => 0, depth => undef },
        { ok => 0, depth => undef },
        { ok => 0, depth => undef },
      ],
      'fk method'
    );
  };

  my $sql_fix = qq/
	UPDATE gene SET gene_id = gene_id - 1
	WHERE gene_id IN (SELECT MAX(gene_id) FROM transcript)
  /;
  $dba->dbc->sql_helper->execute_update($sql_fix);
};

done_testing();
