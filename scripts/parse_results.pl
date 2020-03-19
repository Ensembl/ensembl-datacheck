#!/usr/bin/env perl

=head1 LICENSE

Copyright [2018-2020] EMBL-European Bioinformatics Institute

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

perl parse_results.pl [options]

=head1 OPTIONS

=over 8

=item B<-t[ap]> <tap>

The TAP source to process. Can be a TAP-format file, or a directory
containing such files (sub-directories are ignored).

=item B<-o[utput_file]> <output_file>

The path to an output_file for saving the report.
Defaults to STDOUT if not specified.

=item B<-b[y_species]>

Aggregate failures by species, rather than by datacheck.

=item B<-p[assed]>

Include results for datachecks that passed;
the default is to include only failed datachecks.

=item B<-h[elp]>

Print usage information.

=back

=cut

use warnings;
use strict;
use feature 'say';

use Getopt::Long qw(:config no_ignore_case);
use JSON;
use Path::Tiny;
use Pod::Usage;
use TAP::Parser;

my ($help, $tap, $output_file, $by_species, $passed);

GetOptions(
  "help!",         \$help,
  "tap:s",         \$tap,
  "output_file:s", \$output_file,
  "by_species!",   \$by_species,
  "passed!",       \$passed,
);

pod2usage(1) if $help;

if (! defined $tap) {
  die "Need a source of TAP data";
} elsif (! -e $tap) {
  die "TAP source does not exist: $tap";
}

my @tap_files;
if (-d $tap) {
  @tap_files = map { $_->stringify } path($tap)->children;
} else {
  push @tap_files, $tap;
}

my %results;
my $datacheck;
my $species;
my $test;
my %tests;

foreach my $tap_file (@tap_files) {
  my $tap = path($tap_file)->slurp;
  my $parser = TAP::Parser->new( { tap => $tap } );

  # to-do: extract test number, use that as key with test message and diag messages as lists.
  while (my $result = $parser->next) {
    if ($result->is_comment) {
      next unless $result->as_string =~ /^# Subtest:/;
      # Top-level comment will be the name of the datacheck,
      # the next line will be the species.
      ($datacheck) = $result->as_string =~ /^# Subtest: (.+)/;
      $result = $parser->next;
      ($species) = $result->as_string =~ /\s+# Subtest: (.+)/;
      %tests = ();
    } elsif ($result->is_unknown) {
      if ($result->as_string =~ /^\s{8}((?:not ok|# No tests run).*)/) {
	    $test = $1;
        $tests{$test} = [];
	  } elsif ($result->as_string =~ /^\s{8}((?:ok|.* # SKIP).*)/ && $passed) {
        $test = $1;
        $tests{$test} = [];
	  } elsif ($result->as_string =~ /^\s{8}#\s(\s+.*)/) {
	    push @{$tests{$test}}, $1;
	  }
    } elsif ($result->is_test) {
      my $ok = $result->as_string =~ /^not ok/ ? 0 : 1;
      if (!$ok || $passed) {
        my %datacheck_tests = %tests;
        if ($by_species) {
		  $results{$species}{$datacheck}{'ok'} = $ok;
          $results{$species}{$datacheck}{'tests'} = \%datacheck_tests;
        } else {
		  $results{$datacheck}{$species}{'ok'} = $ok;
          $results{$datacheck}{$species}{'tests'} = \%datacheck_tests;
        }
	  }  
	}
  }
}

my $json = JSON->new->canonical->pretty->encode(\%results);

if ($output_file) {
  path($output_file)->parent->mkpath;
  path($output_file)->spew($json)
} else {
  say $json;
}
