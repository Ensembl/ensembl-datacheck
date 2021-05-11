=head1 LICENSE
Copyright [2018-2021] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 NAME
Bio::EnsEMBL::DataCheck::Pipeline::ConvertTapToJson

=head1 DESCRIPTION
Parse one or more TAP-format output files into a single JSON file.
By default, only failures are included in the JSON file, and the
results are indexed by datacheck name. Results for passing datachecks
can be included by setting '-json_passed => 1', and can be indexed by the
species name/database by setting '-json_by_species => 1'.

=cut

package Bio::EnsEMBL::DataCheck::Pipeline::ConvertTapToJson;

use strict;
use warnings;
use feature 'say';

use JSON;
use Path::Tiny;
use TAP::Parser;

use base ('Bio::EnsEMBL::Hive::Process');

sub param_defaults {
  my $self = shift;

  return {
    output_dir       => undef,
    json_output_file => undef,
    json_by_species  => 0,
    json_passed      => 0
  };
}

sub fetch_input {
  my $self = shift;

  # Whether we are parsing a single TAP-format file or a directory
  # of them, we need a single json output file. If the output_dir
  # is not specified, the output will go to STDOUT - which isn't
  # really useful in a pipeline context, but this code can be used
  # in standalone mode on the command line as well.
  if (
    $self->param_is_defined('output_dir') &&
    ! $self->param_is_defined('json_output_file')
  ) {
    my $filename = 'results';
    $filename   .= '_passed' if $self->param('json_passed');
    $filename   .= '_by_species' if $self->param('json_by_species');
    $filename   .= '.json';
    my $output_file = path($self->param('output_dir'), $filename);
    $self->param('json_output_file', $output_file->stringify);
  }
}

sub run {
  my $self = shift;

  my $tap         = $self->param_required('tap');
  my $output_file = $self->param('json_output_file');
  my $passed      = $self->param('json_passed');
  my $by_species  = $self->param('json_by_species');

  if (-e $tap) {
    $self->parse_results($tap, $output_file, $by_species, $passed);
  }
}

sub write_output {
  my $self = shift;

  my $json_output_file = $self->param('json_output_file');

  if (-e $json_output_file) {
    $self->dataflow_output_id(
      { json_output_file => $json_output_file }, 1
    );
  }
}

sub parse_results {
  my ($self, $tap, $output_file, $by_species, $passed) = @_;

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

    while (my $result = $parser->next) {
      if ($result->is_comment) {
        if ($result->as_string =~ /^# Subtest: (.+)/) {
          $datacheck = $1;
        }
      } elsif ($result->is_unknown) {
        if ($result->as_string =~ /^\s+# Subtest: (.+)/) {
          $species = $1;
          %tests = ();
        } elsif ($result->as_string =~ /^\s{8}((?:not ok|# No tests run).*)/) {
          $test = $1;
          $tests{$test} = [];
        } elsif ($result->as_string =~ /^\s{8}((?:ok|.* # SKIP).*)/ && $passed) {
          $test = $1;
          $tests{$test} = [];
        } elsif ($result->as_string =~ /^\s{8}#\s(\s*.*)/) {
          if (defined $test) {
            push @{$tests{$test}}, $1;
          } else {
            warn "Premature diagnostication: diagnostics incomplete ".
               "for $species because they cannot be linked to a test";
          }
        } elsif ($result->as_string =~ /^\s{4}((?:ok|not ok))/) {
          my $ok = $1 eq 'ok' ? 1 : 0;
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
          $test = undef;
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
}

1;
