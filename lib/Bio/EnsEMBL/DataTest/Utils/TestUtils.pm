=head1 LICENSE

Copyright [2016] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Bio::EnsEMBL::DataTest::Utils::TestUtils;
use warnings;
use strict;
use Carp;
use File::Slurp;
use File::Find;
use Log::Log4perl qw/get_logger/;

BEGIN {
  require Exporter;
  our $VERSION   = 1.00;
  our @ISA       = qw(Exporter);
  our @EXPORT_OK = qw(freeze_builder restore_builder run_test load_tests read_test);
}

# load tests from supplied source file/directory
sub load_tests {
  my ($test_loc) = @_;
  my $logger = get_logger();
  $logger->debug("Test loc $test_loc");
  my $tests = [];
  if ( -f $test_loc ) {
    push @$tests, read_test($test_loc);
  }
  elsif ( -d $test_loc || -l $test_loc ) {
    $logger->debug("Reading tests from $test_loc");
    find( {
        wanted => sub {
          if (m/\.t$/) {
            push @$tests, read_test($_);
          }
        },
        no_chdir => 1,
        follow   => 1 },
      $test_loc );
  }
  else {
    croak("Cannot read test location $test_loc");
  }
  return $tests;
} ## end sub load_tests

# read test from a single file
sub read_test {
  my ($file) = @_;
  my $logger = get_logger();
  $logger->debug("Reading test from $file");
  my $test_str = read_file($file) || croak "Could not read test file $file";
  my $test = eval $test_str;
  if ($@) {
    croak "Could not parse test file $file: $@";
  }
  return $test;
}

sub run_test {
  my ($sub) = @_;
  my $b = freeze_builder( Test::More->builder() );
  Test::More->builder()->reset();
  my $res = &$sub;
  restore_builder( Test::More->builder(), $b );
  return $res;
}

sub freeze_builder {
  my ($builder) = @_;
  my $copy = {};
  for my $k ( keys %$builder ) {
    $copy->{$k} = copy( $builder->{$k} );
  }
  return $copy;
}

sub copy {
  my ($v) = @_;
  my $ov = $v;
  if ( ref($v) eq 'ARRAY' ) {
    $ov = [];
    for my $vv (@$v) {
      push @$ov, copy($vv);
    }
  }
  elsif ( ref($v) eq 'HASHREF' ) {
    $ov = {};
    while ( my ( $k, $vv ) = each %$v ) {
      $ov->{$k} = copy($vv);
    }
  }
  return $ov;
}

sub restore_builder {
  my ( $builder, $settings ) = @_;
  while ( my ( $k, $v ) = each %$settings ) {
    $builder->{$k} = $v;
  }
  return;
}

1;
