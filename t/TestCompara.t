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

# Quis custodiet ipsos custodes?
use Test::Tester;

use Bio::EnsEMBL::DataCheck::Test::Compara;
use Bio::EnsEMBL::Test::MultiTestDB;

use FindBin; FindBin::again();
use Test::Exception;
use Test::More;

my $test_db_dir = $FindBin::Bin;

my $species  = 'multi';
my $db_type  = 'compara';
my $dba_type = 'Bio::EnsEMBL::Compara::DBSQL::DBAdaptor';
my $testdb   = Bio::EnsEMBL::Test::MultiTestDB->new($species, $test_db_dir);
my $dba      = $testdb->get_DBAdaptor($db_type);

my $module = 'Bio::EnsEMBL::DataCheck::Test::Compara';

diag('Methods');
can_ok($module, qw( has_tags cmp_tag check_id_range ));
  
subtest 'MLSS Tags', sub {
  my $real_tags = ['ref_genome_coverage', 'ref_genome_length'];
  my $fake_tags = ['apples', 'bananas'];

  subtest 'has_tags', sub {
    check_tests(
      sub {
        has_tags($dba, 'LASTZ_NET', $real_tags, 'pass: real LASTZ tags');
        has_tags($dba, 'LASTZ_NET', $fake_tags, 'fail: fake LASTZ tags');
      },
      [
        { ok => 1, depth => undef, name => 'pass: real LASTZ tags' },
        { ok => 0, depth => undef },
      ],
      'has_tags method'
    );
  };

  subtest 'cmp_tag', sub {
    my $real_tag = 'non_ref_coding_length';
    my $fake_tag = 'bananas';

  
    check_tests(
      sub {
        cmp_tag($dba, 'LASTZ_NET', $real_tag, '>',  0, 'pass: Greater than comparison');
        cmp_tag($dba, 'LASTZ_NET', $real_tag, '==', 0, 'fail: Equals comparison');
        cmp_tag($dba, 'LASTZ_NET', $real_tag, '!=', 0, 'pass: Not equals comparison');
        cmp_tag($dba, 'LASTZ_NET', $fake_tag, '>',  0, 'fail: fake LASTZ tag');
      },
      [
        { ok => 1, depth => undef, name => 'pass: Greater than comparison' },
        { ok => 0, depth => undef },
        { ok => 1, depth => undef },
        { ok => 0, depth => undef },
      ],
      'cmp_tag method'
    );
  };
};

subtest 'Offset IDs', sub {
  my $real_genome_db_id = 90;
  my $fake_genome_db_id = 1;

  check_tests(
    sub {
      check_id_range($dba, "seq_member", "genome_db_id", $real_genome_db_id);
      check_id_range($dba, "seq_member", "genome_db_id", $fake_genome_db_id);
    },
    [
      { ok => 1, name => "seq_member_id in seq_member is correctly offset by 90", diag => undef, depth => undef },
      { ok => 0, name => "seq_member_id in seq_member is correctly offset by 1", diag => "         got: '0'\n    expected: '1'", depth => undef },
    ],
  );
};

done_testing();
