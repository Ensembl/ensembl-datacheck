#!/usr/bin/env perl

=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

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

perl create_datacheck.pl [options]

=head1 OPTIONS

=over 8

=item B<-n[ame]> <name>

Mandatory. The name of the datacheck, in 'Pascal case', e.g. ForeignKeys.

=item B<-d[escription]> <description>

Mandatory. Short description of datacheck.

=item B<-c[lass]> ['BaseCheck'|'DbCheck']

The Perl class for the datacheck. It is extremely unlikely that you will
need anything other than the default, 'DbCheck'.

=item B<-datacheck_d[ir]> <datacheck_dir>

The directory in which to save the datacheck module. Defaults to the
repository's default value (lib/Bio/EnsEMBL/DataCheck/Checks).
Mandatory if -index_file is specified.

=item B<-i[ndex_file]> <index_file>

The path to the index_file that will be created/updated. Defaults to the
repository's default value (lib/Bio/EnsEMBL/DataCheck/index.json).
Mandatory if -datacheck_dir is specified.

=item B<-g[roups]> <groups>

The groups to which the datacheck belongs, in 'Snake case', e.g. core_handover.
Multiple groups can be given as separate -groups, or as a single
comma-separated string.

=item B<-datacheck_t[ype]> ['critical'|'advisory']

The type of the datacheck. The default in the datacheck framework is
'critical', so you only really need to set this for advisory datachecks.

=item B<-db[_types]> <db_types>

Only relevant for 'DbCheck' class datachecks. The types of database for
which the datacheck is appropriate, e.g. 'core', 'compara'. Multiple db_types
can be given as separate -db_types, or as a single comma-separated string.

=item B<-t[ables]> <tables>

Only relevant for 'DbCheck' class datachecks. The database tables that
contain data used by the datacheck, e.g. 'gene', 'object_xref'. Multiple tables
can be given as separate -tables, or as a single comma-separated string.

=item B<-p[er_db]> [0|1]

Only relevant for 'DbCheck' class datachecks. The default in the datacheck
framework is to run once per species (per_db = 0). For collection
databases it may be appropriate for the datacheck to run once per database
instead.

=item B<-h[elp]>

Print usage information.

=back

=cut

use warnings;
use strict;
use feature 'say';

use Bio::EnsEMBL::DataCheck::Manager;

use File::Copy qw(move);
use File::Spec::Functions qw(catdir);
use Getopt::Long qw(:config no_ignore_case);
use Path::Tiny;
use Pod::Usage;

my (
    $help,
    $name, $description, $class, $datacheck_dir, $index_file,
    @groups, $datacheck_type, @db_types, @tables, $per_db,
);

GetOptions(
  "help!",            \$help,
  "name|n=s",         \$name,
  "description|d=s",  \$description,
  "class:s",          \$class,
  "datacheck_dir:s",  \$datacheck_dir,
  "index_file:s",     \$index_file,
  "groups:s",         \@groups,
  "datacheck_type:s", \$datacheck_type,
  "db_types:s",       \@db_types,
  "tables:s",         \@tables,
  "per_db:i",         \$per_db,
);

pod2usage(1) if $help;

die 'name required' unless defined $name;
die 'description required' unless defined $description;
$class = 'DbCheck' unless defined $class;
die "class '$class' not recognised" unless $class =~ /^BaseCheck|DbCheck$/;

# It doesn't make sense to update the default index file if a datacheck_dir
# is specified (and vice versa); one wants the default directory and index
# to remain in sync.
if (defined $datacheck_dir && ! defined $index_file) {
  die "index_file is mandatory if datacheck_dir is specified";
}
if (! defined $datacheck_dir && defined $index_file) {
  die "datacheck_dir is mandatory if index_file is specified";
}

# We want camel case names; it would be too much effort to make this foolproof,
# but there are some obvious things we can tackle with a simple regex.
$name = ucfirst($name);
$name =~ s/[_\-]+(\w)/\u$1/g;

my @parameters;
my $padding = defined $datacheck_type ? '   ' : '';

if (@groups) {
  @groups = sort map { split(/[,\s]+/, $_) } @groups;
  push @parameters, "GROUPS     $padding => [" . join(", ", map {"'$_'"} @groups) . "]";
}
if (defined $datacheck_type) {
  push @parameters, "DATACHECK_TYPE => '$datacheck_type'";
}
if ($class eq 'DbCheck' && @db_types) {
  @db_types = sort map { split(/[,\s]+/, $_) } @db_types;
  push @parameters, "DB_TYPES   $padding => [" . join(", ", map {"'$_'"} @db_types) . "]";
}
if ($class eq 'DbCheck' && @tables) {
  @tables = sort map { split(/[,\s]+/, $_) } @tables;
  push @parameters, "TABLES     $padding => [" . join(", ", map {"'$_'"} @tables) . "]";
}
if ($class eq 'DbCheck' && defined $per_db) {
  push @parameters, "PER_DB     $padding => $per_db";
}

my $parameters = '';
$parameters .= join(",", map {"\n  $_"} @parameters);

my $copyright = copyright();

my $template = <<"END_TEMPLATE";
package Bio::EnsEMBL::DataCheck::Checks::$name;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::$class';

use constant {
  NAME       $padding => '$name',
  DESCRIPTION$padding => '$description',$parameters
};

sub tests {
  my (\$self) = \@_;

}

1;

END_TEMPLATE

my %manager_params;
$manager_params{datacheck_dir} = $datacheck_dir if defined $datacheck_dir;
$manager_params{index_file}    = $index_file    if defined $index_file;

my $manager = Bio::EnsEMBL::DataCheck::Manager->new(%manager_params);
my $datacheck_file = catdir($manager->datacheck_dir, "$name.pm");

if (-s $datacheck_file) {
  die "A datacheck named '$name' already exists: $datacheck_file";
} else {
  path($datacheck_file)->spew("$copyright$template");
}

# Now we've created it, check we can load it; if not, move it out of the
# datacheck_dir, since one bad egg will prevent the loading of valid checks.
my $error = 0;

$manager->names([$name]);

my $datachecks;

# Update the index, since this is required to load the datacheck.
$manager->write_index();

eval { $datachecks = $manager->load_checks() };
if ($@) {
  say $@;
  $error = 1;
} else {
  my $datacheck = $$datachecks[0];
  $error = 1 unless defined $datacheck;
  $error = 1 unless $datacheck->isa('Bio::EnsEMBL::DataCheck::BaseCheck');
  $error = 1 unless $datacheck->name eq $name;
}

if ($error) {
  my $tmp_file = catdir('/tmp', $ENV{'USER'}."_$name.pm");
  move $datacheck_file, $tmp_file;

  # Remove the datacheck from the index.
  $manager->write_index();

  die "Datacheck '$name' cannot be loaded. File moved to: $tmp_file";
} else {
  say "Created datacheck '$datacheck_file'";
}

sub copyright {
return <<'END_COPYRIGHT';
=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the 'License');
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an 'AS IS' BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

END_COPYRIGHT
}
