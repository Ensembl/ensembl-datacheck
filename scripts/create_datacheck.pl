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

use File::Copy qw(move);
use File::Spec::Functions qw(catdir);
use Path::Tiny;

use Getopt::Long qw(:config no_ignore_case);

my ($class, $name, $description, @groups, $datacheck_type,
    @db_types, @tables, $per_db,
);

GetOptions(
  "class:s",          \$class,
  "name=s",           \$name,
  "description=s",    \$description,
  "groups:s",         \@groups,
  "datacheck_type:s", \$datacheck_type,
  "db_types:s",       \@db_types,
  "tables:s",         \@tables,
  "per_db:i",         \$per_db,
);

$class = 'DbCheck' unless defined $class;
die "class '$class' not recognised" unless $class =~ /^BaseCheck|DbCheck$/;
die 'name required' unless defined $name;
die 'description required' unless defined $description;

$name = ucfirst($name);

my @parameters;
my $padding = defined $datacheck_type ? '   ' : '';

if (@groups) {
  @groups = sort map { split(/[,\s]+/, $_) } @groups;
  push @parameters, "GROUPS     $padding => [" . join(", ", map {"'$_'"} @groups) . "]";
}
if (defined $datacheck_type) {
  push @parameters, "DATACHECK_TYPE => '$datacheck_type'";
}
if (@db_types) {
  @db_types = sort map { split(/[,\s]+/, $_) } @db_types;
  push @parameters, "DB_TYPES   $padding => [" . join(", ", map {"'$_'"} @db_types) . "]";
}
if (@tables) {
  @tables = sort map { split(/[,\s]+/, $_) } @tables;
  push @parameters, "TABLES     $padding => [" . join(", ", map {"'$_'"} @tables) . "]";
}
if (defined $per_db) {
  push @parameters, "PER_DB$padding => $per_db";
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

my $manager = Bio::EnsEMBL::DataCheck::Manager->new();
my $datacheck_dir  = $manager->datacheck_dir;
my $datacheck_file = catdir($datacheck_dir, "$name.pm");

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

$manager->write_index();

eval { $datachecks = $manager->load_checks() };
if ($@) {
  say $@;
  $error = 1;
} else {
  my $datacheck = $$datachecks[0];
  $error = 1 unless $datacheck->isa('Bio::EnsEMBL::DataCheck::BaseCheck');
  $error = 1 unless $datacheck->name eq $name;
}

if ($error) {
  my $tmp_file = catdir('/tmp', $ENV{'USER'}."_$name.pm");
  move $datacheck_file, $tmp_file;
  die "Datacheck '$name' cannot be loaded. File moved to: $tmp_file";
} else {
  say "Created datacheck '$datacheck_file'";
}

sub copyright {
return <<'END_COPYRIGHT';
=head1 LICENSE

Copyright [2018] EMBL-European Bioinformatics Institute

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
