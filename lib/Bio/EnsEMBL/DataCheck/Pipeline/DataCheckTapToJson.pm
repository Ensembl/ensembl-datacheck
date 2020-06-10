=head1 LICENSE
Copyright [2018-2020] EMBL-European Bioinformatics Institute

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
Bio::EnsEMBL::DataCheck::Pipeline::DataCheckSummary

=head1 DESCRIPTION
Store summary of datacheck results, and optionally send it via email.

=cut

package Bio::EnsEMBL::DataCheck::Pipeline::DataCheckTapToJson;

use strict;
use warnings;
use feature 'say';

use JSON;
use Path::Tiny;
use Pod::Usage;
use TAP::Parser;


use base ('Bio::EnsEMBL::Hive::Process');
sub run {

  my $self = shift;

  my $output_dir   = $self->param('output_dir');
  my @tap_files = map { $_->stringify } path($output_dir)->children;
  
  my %results;
  my $datacheck;
  my $species;
  my $test;
  my %tests;
  my $passed = 1;
  my $by_species = 1;

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
  my $basename = path($output_dir)->basename;
  my $output_file = $output_dir . '/' . $basename . '.json';
  path($output_file)->parent->mkpath;
  path($output_file)->spew($json)

}

1;
  
