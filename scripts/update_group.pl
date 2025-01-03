#!/usr/bin/env perl

=head1 LICENSE

Copyright [2018-2025] EMBL-European Bioinformatics Institute

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

perl create_group.pl [options]

=head1 OPTIONS

=over 8

=item B<-g[roup]> <group>

Mandatory. The new group name, in 'Snake case', e.g. core_handover.

=item B<-n[ames]> <names>

Mandatory. The names of the datachecks to be added to the new group.
Multiple names can be given as separate -names, or as a single
comma-separated string.

=item B<-a[ction]> 'add'|'remove'

Whether to add or remove the group from the specified datachecks.

=item B<-d[atacheck_dir]> <datacheck_dir>

The directory in which to find the datacheck module. Defaults to the
repository's default value (lib/Bio/EnsEMBL/DataCheck/Checks).
Mandatory if -index_file is specified.

=item B<-i[ndex_file]> <index_file>

The path to the index_file that will be updated. Defaults to the
repository's default value (lib/Bio/EnsEMBL/DataCheck/index.json).
Mandatory if -datacheck_dir is specified.

=item B<-h[elp]>

Print usage information.

=back

=cut

use warnings;
use strict;
use feature 'say';

use Bio::EnsEMBL::DataCheck::Manager;

use File::Spec::Functions qw(catdir);
use Getopt::Long qw(:config no_ignore_case);
use Path::Tiny;
use Pod::Usage;

my (
    $help,
    $group, @names, $action, $datacheck_dir, $index_file,
);

GetOptions(
  "help!",           \$help,
  "group=s",         \$group,
  "names:s",         \@names,
  "action=s",        \$action,
  "datacheck_dir:s", \$datacheck_dir,
  "index_file:s",    \$index_file,
);

pod2usage(1) if $help;

die 'group required' unless defined $group;
die 'names required' unless scalar @names;
$action = 'add' unless defined $action;

if ($action !~ /^(add|remove)$/) {
  die "action must be either 'add' or 'remove'";
}

# It doesn't make sense to update the default index file if a datacheck_dir
# is specified (and vice versa); one wants the default directory and index
# to remain in sync.
if (defined $datacheck_dir && ! defined $index_file) {
  die "index_file is mandatory if datacheck_dir is specified";
}
if (! defined $datacheck_dir && defined $index_file) {
  die "datacheck_dir is mandatory if index_file is specified";
}

my %manager_params;
$manager_params{datacheck_dir} = $datacheck_dir if defined $datacheck_dir;
$manager_params{index_file}    = $index_file    if defined $index_file;

my $manager = Bio::EnsEMBL::DataCheck::Manager->new(%manager_params);

# Open index to get list of current datacheck groups.
my $index = $manager->read_index();

@names = sort map { split(/[,\s]+/, $_) } @names;

foreach my $name (@names) {
  my %groups = map { $_ => 1 } @{$$index{$name}{groups}};
  if ($action eq 'add') {
    $groups{$group} = 1;
  } elsif ($action eq 'remove') {
    delete $groups{$group};
  }
  my $groups_string = "[" . join(", ", map {"'$_'"} sort keys %groups) . "]";

  my $datacheck_file = catdir($manager->datacheck_dir, "$name.pm");
  my $datacheck = path($datacheck_file)->slurp;
  $datacheck =~ s/(^\s+GROUPS\s+=>\s+)\[.+\]/$1$groups_string/m;

  path($datacheck_file)->spew($datacheck);
}

# Update the index to include the added/removed group.
$manager->write_index();

if ($action eq 'add') {
  say "Added group '$group' to datachecks: ".join(', ', @names);
} elsif ($action eq 'remove') {
  say "Removed group '$group' from datachecks: ".join(', ', @names);
}
