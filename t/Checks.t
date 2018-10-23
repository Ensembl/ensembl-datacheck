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

use Bio::EnsEMBL::DataCheck::Manager;
use Bio::EnsEMBL::Test::MultiTestDB;

use FindBin; FindBin::again();
use Path::Tiny;
use Test::Exception;
use Test::More;

my $test_db_dir = $FindBin::Bin;
my @species     = qw(collection drosophila_melanogaster homo_sapiens);
my $db_type     = 'core';
my $dba_type    = 'Bio::EnsEMBL::DBSQL::DBAdaptor';

# We don't run all datachecks in this test; it's complicated to
# provide other databases (e.g. production, metadata), and would
# get increasingly slow and unmanageable. So we run a subset.
# But, we do load all datachecks; the Manager module evals the
# modules when datachecks are loaded, so this allows us to check for
# Perl syntax errors.

my $output_file = Path::Tiny->tempfile->stringify;
my $manager = Bio::EnsEMBL::DataCheck::Manager->new(output_file => $output_file);

subtest 'Load all datachecks', sub {
  my $datachecks = $manager->load_checks();
  ok(scalar(@$datachecks), 'Datachecks loaded');
};

foreach my $species (@species) {
  my $testdb = Bio::EnsEMBL::Test::MultiTestDB->new($species, $test_db_dir);
  my $dba    = $testdb->get_DBAdaptor($db_type);

  subtest 'Run subset of datachecks', sub {
    # Note that we don't care if the datachecks pass or fail; that's not
    # meaningful for a test db, we just want to ensure that datachecks run.

    my @names = qw/
      AssemblyAccession
      CompareSchema
      ForeignKeys
      GeneBounds
      SchemaVersion
    /;
    $manager->names(\@names);

    my ($datachecks) = $manager->run_checks(dba => $dba);
    is(scalar(@$datachecks), 5, 'Datachecks run');
  };
}

done_testing();
