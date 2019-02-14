=head1 LICENSE

Copyright [2018-2019] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the 'License');
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an 'AS IS' BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 SYNOPSIS

perl run_datachecks.pl [options]

=head1 OPTIONS

=over 8

=item B<-host|H> <host>

=item B<-port|P> <port>

=item B<-user|u> <user>

=item B<-password|p> <password>

=item B<-dbn[ame]> <dbname>

Name of the database against which tests will be run.

=item B<-dbt[ype]> <dbtype>

By default, the type of database is inferred from the dbname; it only needs 
to be specified if the db is named in a non-standard manner.

=item B<-r[egistry_file]> <registry_file>

Some datachecks need to connect to other databases, such as the metadata 
database. Such datachecks will know _what_ to look for, but a registry file 
is needed so that they know _where_ to look.

=item B<-s[erver_uri]> <server_uri>

As an alternative to providing a registry file (see above), a URI can be
given, e.g. mysql://a_user@some_host:port_number/

=item B<-ol[d_server_uri]> <old_server_uri>

For comparisons with an analogous database from a previous release it is
not possible to load them via the registry_file.
A URI must be specified with the location of the previous release's databases,
e.g. mysql://a_user@some_host:port_number/[old_db_name|old_release_number]

=item B<-data_f[ile_path]> <data_file_path>

Path to a directory containing data files that need to be tested
as part of some datachecks (currently only applies to funcgen).

=item B<-c[onfig_file]> <config_file>

Path to a config file that contains default values for parameters
needed by datachecks. If not explicitly specified, then the config.json
file in the repository's root directory will be used, if it exists.
The values in this file are overridden by any specific parameters
that are given to this script.

=item B<-n[ames]> <names>

The name of the datacheck to execute.
Multiple names can be given as separate -n[ame] parameters, 
or as a single comma-separated string.

=item B<-pat[terns]> <patterns>

A pattern (i.e. Perl regex) that is matched against datacheck names _and_
descriptions, and the resulting set of datachecks is executed.
Multiple patterns can be given as separate -pat[tern] parameters, 
or as a single comma-separated string.

=item B<-g[roups]> <groups>

The name of a group of datachecks to execute.
Multiple groups can be given as separate -g[roup] parameters, 
or as a single comma-separated string.

=item B<-datacheck_t[ype]> [critical|advisory]

The type of datachecks to execute. 

=item B<-datacheck_d[ir]> <datacheck_dir>

The directory containing the datacheck modules. Defaults to the repository's
default value (lib/Bio/EnsEMBL/DataCheck/Checks). 
Mandatory if -index_file is specified.

=item B<-i[ndex_file]> <index_file>

The path to the index_file that will be created/updated. Defaults to the
repository's default value (lib/Bio/EnsEMBL/DataCheck/index.json). 
Mandatory if -datacheck_dir is specified.

=item B<-hi[story_file]> <history_file>

Path to a file to store basic information about the datacheck execution.
This is used in subsequent runs to determine if anything has changed in the
data since the last run, and thus whether datachecks need to be run.
If the file already exists, information from the current run will be merged
with what is already there.

=item B<-ou[tput_file]> <output_file>

Path to a file to store full output in TAP format.
If the file already exists, it will be overwritten.

=item B<-h[elp]>

Print usage information.

=back

=cut

use warnings;
use strict;
use feature 'say';

use Bio::EnsEMBL::DataCheck::Manager;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Compara::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Funcgen::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Variation::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Registry;

use DBI;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;

my (
    $help,
    $host, $port, $user, $pass, $dbname, $dbtype,
    $registry_file, $server_uri, $old_server_uri, $data_file_path, $config_file,
    @names, @patterns, @groups, @datacheck_types,
    $datacheck_dir, $index_file, $history_file, $output_file,
);

GetOptions(
  "h|help!",           \$help,
  "H|host=s",          \$host,
  "P|port=i",          \$port,
  "user=s",            \$user,
  "p|password=s",      \$pass,
  "dbname=s",          \$dbname,
  "dbtype=s",          \$dbtype,
  "registry_file=s",   \$registry_file,
  "server_uri=s",      \$server_uri,
  "old_server_uri=s",  \$old_server_uri,
  "data_file_path=s",  \$data_file_path,
  "config_file=s",     \$config_file,
  "names|n:s",         \@names,
  "patterns:s",        \@patterns,
  "groups:s",          \@groups,
  "datacheck_types:s", \@datacheck_types,
  "datacheck_dir:s",   \$datacheck_dir,
  "index_file:s",      \$index_file,
  "history_file:s",    \$history_file,
  "output_file:s",     \$output_file,
);

pod2usage(1) if $help;

my $dba;
if ($dbname) {
  if (! defined $dbtype) {
    if ($dbname =~ /_compara_/) {
      $dbtype = 'compara';
    } else {
      ($dbtype) = $dbname =~ /_([a-z]+)[\d_]+$/;
    }
  }
  die "Could not derive database type from dbname" unless defined $dbtype;

  my $adaptor = 'Bio::EnsEMBL::DBSQL::DBAdaptor';
  $adaptor = 'Bio::EnsEMBL::Compara::DBSQL::DBAdaptor'   if $dbtype eq 'compara';
  $adaptor = 'Bio::EnsEMBL::Funcgen::DBSQL::DBAdaptor'   if $dbtype eq 'funcgen';
  $adaptor = 'Bio::EnsEMBL::Variation::DBSQL::DBAdaptor' if $dbtype eq 'variation';

  my $multispecies_db = $dbname =~ /^\w+_collection_core_\w+$/;

  my $species;
  if ($dbtype eq 'compara') {
    $species = 'Multi';
  } else {
    my $sql = q/
      SELECT meta_value FROM meta
      WHERE meta_key = "species.production_name" AND species_id = 1
    /;
    my $dsn  = "DBI:mysql:database=$dbname;host=$host;port=$port";
    my %attr = ( PrintError => 0, RaiseError => 1 );
    my $dbh  = DBI->connect($dsn, $user, $pass, \%attr);
    my $vals = $dbh->selectcol_arrayref($sql);
    $species = $vals->[0];
  }

  $dba = $adaptor->new(
    -host            => $host,
    -port            => $port,
    -user            => $user,
    -pass            => $pass,
    -dbname          => $dbname,
    -species         => $species,
    -group           => $dbtype,
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

# If datacheck parameters have been specified as comma-separated strings,
# convert them into arrays.
@names = map { split(/[,\s]+/, $_) } @names if scalar @names;
@patterns = map { split(/[,\s]+/, $_) } @patterns if scalar @patterns;
@groups = map { split(/[,\s]+/, $_) } @groups if scalar @groups;
@datacheck_types = map { split(/[,\s]+/, $_) } @datacheck_types if scalar @datacheck_types;

my %manager_params;
$manager_params{names}           = \@names           if scalar @names;
$manager_params{patterns}        = \@patterns        if scalar @patterns;
$manager_params{groups}          = \@groups          if scalar @groups;
$manager_params{datacheck_types} = \@datacheck_types if scalar @datacheck_types;
$manager_params{datacheck_dir}   = $datacheck_dir    if defined $datacheck_dir;
$manager_params{index_file}      = $index_file       if defined $index_file;
$manager_params{history_file}    = $history_file     if defined $history_file;
$manager_params{output_file}     = $output_file      if defined $output_file;
$manager_params{config_file}     = $config_file      if defined $config_file;

my %datacheck_params;
$datacheck_params{dba}            = $dba            if defined $dba;
$datacheck_params{registry_file}  = $registry_file  if defined $registry_file;
$datacheck_params{server_uri}     = $server_uri     if defined $server_uri;
$datacheck_params{old_server_uri} = $old_server_uri if defined $old_server_uri;
$datacheck_params{data_file_path} = $data_file_path if defined $data_file_path;

my $manager = Bio::EnsEMBL::DataCheck::Manager->new(%manager_params);

my ($datachecks, $aggregator) = $manager->run_checks(%datacheck_params);
