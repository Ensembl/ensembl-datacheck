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
#use JSON;
#use Path::Tiny;
#use Pod::Usage;
#use TAP::Parser;
#use Bio::EnsEMBL::DataCheck::Pipeline::DataCheckTapToJson;

my ($help, $tap, $output_file, $by_species, $passed);

GetOptions(
  "help!",         \$help,
  "tap:s",         \$tap,
  "output_file:s", \$output_file,
  "by_species!",   \$by_species,
  "passed!",       \$passed
);

pod2usage(1) if $help;
if (! defined $tap) {
  die "Need a source of TAP data";
} elsif (! -e $tap) {
  die "TAP source does not exist: $tap";
}

my $parse_cmd =
  "standaloneJob.pl ".
  " Bio::EnsEMBL::DataCheck::Pipeline::DataCheckTapToJson".
  " -tap $tap";
$parse_cmd .= " -json_output_file $output_file" if defined $output_file;
$parse_cmd .= " -json_by_species $by_species" if defined $by_species;
$parse_cmd .= " -json_passed $passed" if defined $passed;

my $parse_return = system($parse_cmd);
exit $parse_return;
