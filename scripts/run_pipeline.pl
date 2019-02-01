=head1 LICENSE

Copyright [2019] EMBL-European Bioinformatics Institute

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

perl run_pipeline.pl [options]

=head1 OPTIONS

=over 8

=item B<-pipeline_host|phost|H> <pipeline_host>

=item B<-pipeline_port|pport|P> <pipeline_port>

=item B<-pipeline_user|puser|u> <pipeline_user>

=item B<-pipeline_password|ppassword|p> <pipeline_password>

=item B<-pipeline_dbname|pdbname> <pipeline_dbname>

Name of the pipeline database, defaults to 'B<$USER>_db_datachecks'.

=item B<-drop_pipeline_db>

By default, if the pipeline database already exists, the new batch of
datachecks will be added to it. This parameter changes that behaviour,
and overwrites the old database.

=item B<-registry_file> <registry_file>

Databases are selected using the SpeciesFactory module; a registry file
is required in order to locate those databases. If the databases being
checked require connections to other databases, those also need to be
in the registry (e.g. funcgen datachecks need access to core databases).

=item B<-old_server_uri> <old_server_uri>

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

=item B<-dbtype> <dbtype>

By default, 'core' databases will be checked. Valid options are
any Ensembl database group, e.g. 'compara', 'funcgen', 'rnaseq'

=item B<-species> <species>

The name of the species on which to run datachecks.
Multiple species can be given as separate -species parameters, 
or as a single comma-separated string.

=item B<-taxons> <taxons>

The name of the taxon on which to run datachecks.
Multiple taxons can be given as separate -taxon parameters, 
or as a single comma-separated string.

=item B<-division> <division>

The name of the division on which to run datachecks.
Multiple divisions can be given as separate -division parameters, 
or as a single comma-separated string.

=item B<-run_all> [0|1]

Run datachecks for all species, all divisions if set to 1 (default is 0).

=item B<-antispecies> <antispecies>

The name of the species to exclude from datachecks
(used in combination with -division or -run_all).
Multiple antispecies can be given as separate -antispecies parameters, 
or as a single comma-separated string.

=item B<-antitaxons> <antitaxons>

The name of the taxon to exclude from datachecks
(used in combination with -division or -run_all).
Multiple antitaxons can be given as separate -antitaxons parameters, 
or as a single comma-separated string.

=item B<-names> <name>

The name of the datacheck to execute.
Multiple names can be given as separate -n[ame] parameters, 
or as a single comma-separated string.

=item B<-patterns> <pattern>

A pattern (i.e. Perl regex) that is matched against datacheck names _and_
descriptions, and the resulting set of datachecks is executed.
Multiple patterns can be given as separate -pat[tern] parameters, 
or as a single comma-separated string.

=item B<-groups> <group>

The name of a group of datachecks to execute.
Multiple groups can be given as separate -g[roup] parameters, 
or as a single comma-separated string.

=item B<-datacheck_type> [critical|advisory]

The type of datachecks to execute. 

=item B<-datacheck_dir> <datacheck_dir>

The directory containing the datacheck modules. Defaults to the repository's
default value (lib/Bio/EnsEMBL/DataCheck/Checks). 
Mandatory if -index_file is specified.

=item B<-index_file> <index_file>

The path to the index_file that will be created/updated. Defaults to the
repository's default value (lib/Bio/EnsEMBL/DataCheck/index.json). 
Mandatory if -datacheck_dir is specified.

=item B<-history_file> <history_file>

Path to a file to store basic information about the datacheck execution.
This is used in subsequent runs to determine if anything has changed in the
data since the last run, and thus whether datachecks need to be run.
If the file already exists, information from the current run will be merged
with what is already there.

=item B<-output_dir> <output_dir>

Path to a directory in which to store full output in TAP format.
Files will be created with the same names as the databases.

=item B<-parallelize_datachecks>

By default, datachecks for each database are run consecutively,
i.e. the only paralleization is across databases. This is usually the
most efficient approach, (e.g. it allows datachecks to re-use DBAdaptors).
But it is possible to parallelize across datachecks, if you're in a hurry.

=item B<-tag> <tag>

A short description to associate with a batch of healthchecks.

=item B<-email> <email>

An email address to send summary reports.

=item B<-report_per_db>

By default, a single summary report is sent, if B<-email> is set.
This parameter enables one per database, additionally.

=item B<-report_all>

If B<-report_per_db> is set, by default the pipeline will only send
reports if any datachecks fail. This parameter enables reports for
databases that pass all datachecks.

=item B<-h[elp]>

Print usage information.

=back

=cut

use warnings;
use strict;
use feature 'say';

use Bio::EnsEMBL::Registry;

use Data::Dumper;
local $Data::Dumper::Terse = 1;
use DBI;
use FindBin; FindBin::again();
use Getopt::Long qw(:config no_ignore_case);
use JSON;
use Path::Tiny;
use Pod::Usage;
use Time::Piece;

my (
    $help,
    $host, $port, $user, $pass, $dbname, $drop_db,
    $registry_file, $old_server_uri, $data_file_path, $config_file, $dbtype,
    @species, @taxons, @divisions, $run_all, @antispecies, @antitaxons,
    @names, @patterns, @groups, @datacheck_types,
    $datacheck_dir, $index_file, $history_file, $output_dir,
    $parallelize_datachecks,
    $tag, $email, $report_per_db, $report_all
);

GetOptions(
  "h|help!", \$help,

  "H|pipeline_host|phost=s",         \$host,
  "P|pipeline_port|pport=i",         \$port,
  "u|pipeline_user|puser=s",         \$user,
  "p|pipeline_password|ppassword=s", \$pass,
  "pipeline_dbname|pdbname:s",       \$dbname,
  "drop_pipeline_db",                \$drop_db,

  "registry_file=s",  \$registry_file,
  "old_server_uri:s", \$old_server_uri,
  "data_file_path:s", \$data_file_path,
  "config_file:s",    \$config_file,
  "dbtype|db_type:s", \$dbtype,
  "species:s",        \@species,
  "taxons:s",         \@taxons,
  "divisions:s",      \@divisions,
  "run_all",          \$run_all,
  "antispecies:s",    \@antispecies,
  "antitaxons:s",     \@antitaxons,

  "names|n:s",         \@names,
  "patterns:s",        \@patterns,
  "groups:s",          \@groups,
  "datacheck_types:s", \@datacheck_types,
  "datacheck_dir:s",   \$datacheck_dir,
  "index_file:s",      \$index_file,
  "history_file:s",    \$history_file,
  "output_dir:s",      \$output_dir,

  "parallelize_datachecks|parallelise_datachecks", \$parallelize_datachecks,

  "tag:s",         \$tag,
  "email:s",       \$email,
  "report_per_db", \$report_per_db,
  "report_all",    \$report_all,
);

pod2usage(1) if $help;

if (! defined $host || ! defined $port || ! defined $user || ! defined $pass) {
  die "pipeline host, port, user and password are mandatory";
}
$dbname = $ENV{'USER'}.'_db_datachecks'unless defined $dbname;

if (! defined $registry_file) {
  if (! defined $config_file) {
    $config_file = $FindBin::Bin;
    $config_file =~ s!scripts$!config.json!;
  }

  if (-e $config_file) {
    my $json = path($config_file)->slurp;
    my %config = %{ JSON->new->decode($json) };
    if (exists $config{registry_file} && defined $config{registry_file}) {
      $registry_file = $config{registry_file};
    } else {
      die "registry_file is mandatory";
    }
  } else {
    die "registry_file is mandatory";
  }
}
if (! -e $registry_file) {
  die "registry_file '$registry_file' does not exist";
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

# Only initialise the hive pipeline db if we have to.
my $initialise = 0;
if ($drop_db) {
  $initialise = 1;
} else {
  my $dsn = "DBI:mysql:database=$dbname;host=$host;port=$port";
  my $dbh  = DBI->connect($dsn, $user, $pass, { PrintError => 0 });
  if (! defined $dbh) {
    my $err = $DBI::errstr;
    if ($err !~ /Unknown database/m) {
      die "Connection problem for $dsn\n$err";
    }
    $initialise = 1;
  }
}

if ($initialise) {
  my $init_cmd = 
    "init_pipeline.pl Bio::EnsEMBL::DataCheck::Pipeline::DbDataChecks_conf".
    " -pipeline_db -host=$host".
    " -pipeline_db -port=$port".
    " -pipeline_db -user=$user".
    " -pipeline_db -pass=$pass".
    " -pipeline_db -dbname=$dbname".
    " -hive_force_init 1";

  my $init_return = system($init_cmd);
  exit $init_return if $init_return;
}

my $url = "mysql://$user:$pass\@$host:$port/$dbname";

my %input_id = (
  registry_file => $registry_file,
  timestamp     => localtime->cdate,
);
$input_id{old_server_uri} = $old_server_uri if defined $old_server_uri;
$input_id{data_file_path} = $data_file_path if defined $data_file_path;
$input_id{db_type} = $dbtype if defined $dbtype;
$input_id{species} = \@species if scalar @species;
$input_id{taxons} = \@taxons if scalar @taxons;
$input_id{division} = \@divisions if scalar @divisions;
$input_id{run_all} = $run_all if defined $run_all;
$input_id{antispecies} = \@antispecies if scalar @antispecies;
$input_id{antitaxons} = \@antitaxons if scalar @antitaxons;
$input_id{datacheck_names} = \@names if scalar @names;
$input_id{datacheck_patterns} = \@patterns if scalar @patterns;
$input_id{datacheck_groups} = \@groups if scalar @groups;
$input_id{datacheck_types} = \@datacheck_types if scalar @datacheck_types;
$input_id{datacheck_dir} = $datacheck_dir if defined $datacheck_dir;
$input_id{index_file} = $index_file if defined $index_file;
$input_id{history_file} = $history_file if defined $history_file;
$input_id{output_dir} = $output_dir if defined $output_dir;
$input_id{config_file} = $config_file if defined $config_file;
$input_id{parallelize_datachecks} = $parallelize_datachecks if defined $parallelize_datachecks;
$input_id{tag} = $tag if defined $tag;
$input_id{email} = $email if defined $email;
$input_id{report_per_db} = $report_per_db if defined $report_per_db;
$input_id{report_all} = $report_all if defined $report_all;

my $input_id = Dumper(\%input_id);

my $seed_cmd =
  "seed_pipeline.pl ".
  " -url $url".
  " -logic_name DataCheckSubmission".
  " -input_id \"$input_id\"";

my $seed_return = system($seed_cmd);

if (! $seed_return) {
  say "If a beekeeper is not already running, start one with:";
  say "beekeeper.pl -url $url -loop";
}

exit $seed_return;
