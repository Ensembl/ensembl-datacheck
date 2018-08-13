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
use Bio::EnsEMBL::Compara::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Funcgen::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Variation::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Registry;

use Getopt::Long qw(:config no_ignore_case);

my ($host, $port, $user, $pass, $dbname,
    $registry_file, $server_uri, $old_server_uri,
    @names, @patterns, @groups, @datacheck_types,
    $datacheck_dir, $index_file, $history_file, $output_file,
);

GetOptions(
  "host=s",              \$host,
  "P|port=i",            \$port,
  "user=s",              \$user,
  "p|pass=s",            \$pass,
  "dbname=s",            \$dbname,
  "registry_file=s",     \$registry_file,
  "server_uri=s",        \$server_uri,
  "old_server_uri=s",    \$old_server_uri,
  "names:s",             \@names,
  "patterns:s",          \@patterns,
  "groups:s",            \@groups,
  "datacheck_types:s",   \@datacheck_types,
  "datacheck_dir:s",     \$datacheck_dir,
  "index_file:s",        \$index_file,
  "history_file:s",      \$history_file,
  "output_file:s",       \$output_file,
);

my $dba;
if ($dbname) {
  my $adaptor = 'Bio::EnsEMBL::DBSQL::DBAdaptor';
  $adaptor = 'Bio::EnsEMBL::Compara::DBSQL::DBAdaptor'   if $dbname =~ /_compara_/;
  $adaptor = 'Bio::EnsEMBL::Funcgen::DBSQL::DBAdaptor'   if $dbname =~ /_funcgen_/;
  $adaptor = 'Bio::EnsEMBL::Variation::DBSQL::DBAdaptor' if $dbname =~ /_variation_/;

  my $multispecies_db = $dbname =~ /^\w+_collection_core_\w+$/;

  $dba = $adaptor->new(
    -host            => $host,
    -port            => $port,
    -user            => $user,
    -pass            => $pass,
    -dbname          => $dbname,
    -multispecies_db => $multispecies_db,
  );
}

# It doesn't make sense to use the default index file if a datacheck_dir
# is specified (and vice versa).
if (defined $datacheck_dir && ! defined $index_file) {
  die "index_file is mandatory if datacheck_dir is specified";
}
if (! defined $datacheck_dir && defined $index_file) {
  die "datacheck_dir is mandatory if index_file is specified";
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
$datacheck_params{dba}            = $dba            if defined $dba;
$datacheck_params{registry_file}  = $registry_file  if defined $registry_file;
$datacheck_params{server_uri}     = $server_uri     if defined $server_uri;
$datacheck_params{old_server_uri} = $old_server_uri if defined $old_server_uri;

my $manager = Bio::EnsEMBL::DataCheck::Manager->new(%manager_params);

my ($datachecks, $aggregator) = $manager->run_checks(%datacheck_params);
