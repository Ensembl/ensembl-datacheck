# Copyright [2018] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use warnings;
use strict;
use feature 'say';

use Bio::EnsEMBL::DataCheck::Manager;
use Bio::EnsEMBL::DBSQL::DBAdaptor;

use Getopt::Long qw(:config no_ignore_case);

my ($host, $port, $user, $pass, $dbname,
    $second_host, $second_port, $second_user, $second_pass, $second_dbname,
    @names, @patterns, @groups, @datacheck_types,
    $datacheck_dir, $history_file, $output_file,
);

GetOptions(
  "host=s",            \$host,
  "P|port=i",          \$port,
  "user=s",            \$user,
  "p|pass=s",          \$pass,
  "dbname=s",          \$dbname,
  "second_host=s",     \$second_host,
  "second_port=i",     \$second_port,
  "second_user=s",     \$second_user,
  "second_pass=s",     \$second_pass,
  "second_dbname=s",   \$second_dbname,
  "names:s",           \@names,
  "patterns:s",        \@patterns,
  "groups:s",          \@groups,
  "datacheck_types:s", \@datacheck_types,
  "datacheck_dir:s",   \$datacheck_dir,
  "index_file:s",      \$index_file,
  "history_file:s",    \$history_file,
  "output_file:s",     \$output_file,
);

# This will only work with core dbs at the minute...
# Pick up group from $dbname and adjust class accordingly?

my $dba;
if ($dbname) {
  my $multispecies_db = $dbname =~ /^\w+_collection_core_\w+$/;

  $dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
    -host            => $host,
    -port            => $port,
    -user            => $user,
    -pass            => $pass,
    -dbname          => $dbname,
    -multispecies_db => $multispecies_db,
  );
}

my $second_dba;
if ($second_dbname) {
  my $multispecies_db = $second_dbname =~ /^\w+_collection_core_\w+$/;

  $second_dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
    -host            => $second_host,
    -port            => $second_port,
    -user            => $second_user,
    -pass            => $second_pass,
    -dbname          => $second_dbname,
    -multispecies_db => $multispecies_db,
  );
}

my %manager_params;
$manager_params{names}           = \@names           if scalar @names;
$manager_params{patterns}        = \@patterns        if scalar @patterns;
$manager_params{groups}          = \@groups          if scalar @groups;
$manager_params{datacheck_types} = \@datacheck_types if scalar @datacheck_types;
$manager_params{datacheck_dir}   = $datacheck_dir    if defined $datacheck_dir;
$manager_params{index_file}      = $index_file       if defined $index_file;
$manager_params{history_file}    = $history_file     if defined $history_file;
$manager_params{output_file}     = $output_file      if defined $output_file;

my %datacheck_params;
$datacheck_params{'Bio::EnsEMBL::DataCheck::DbCheck'}{dba}          = $dba        if defined $dba;
$datacheck_params{'Bio::EnsEMBL::DataCheck::DbDbCheck'}{second_dba} = $second_dba if defined $second_dba;

my $manager = Bio::EnsEMBL::DataCheck::Manager->new(%manager_params);

my ($datachecks, $aggregator) = $manager->run_checks(%datacheck_params);
