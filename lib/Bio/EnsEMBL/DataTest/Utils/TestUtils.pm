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

=head1 NAME

Bio::EnsEMBL::DataTest::Utils::TestUtils

=head1 SYNOPSIS

my $tests = load_tests($test_loc);


=head1 DESCRIPTION

Utilities used to load and execute tests (see run_tests.pl and Bio::EnsEMBL::DataTest::BaseTest)

=head1 METHODS

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

=head2 load_tests

  Arg [1]    : Directory or file
  Example    : my $tests = load_tests("./t");
  Description: load tests from supplied source file/directory
  Returntype : Arrayref of test objects
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut
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

=head2 read_test

  Arg [1]    : File to read from
  Example    : my $test = read_test("test.t");
  Description: read test from a single file
  Returntype : test object
  Exceptions : none
  Caller     : load_tests
  Status     : Stable

=cut
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

=head2 run_test

  Arg [1]    : Coderef for tests
  Example    : see Bio::EnsEMBL::DataTest::BaseTest
  Description: Execute code containing Test::More tests and capture the results
  Returntype : hashref of results
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut
sub run_test {
  
  my ($sub) = @_;
  
  # freeze the builder
  my $b = freeze_builder( Test::More->builder() );
  
  # reset the builder to a clean sheet
  Test::More->builder()->reset();
  
  # redirect output to a scalar
  my $output       = '';
  Test::More->builder()->output( \$output );
  Test::More->builder()->failure_output( \$output );
  
  # execute the test routine
  my $res = &$sub;
  
  # capture and return the results
  my @details = Test::More->builder()->details();
  my $is_passing = Test::More->builder()->is_passing();
  
  # restore the builder status
  restore_builder( Test::More->builder(), $b );
  return { skipped => 0,
              pass    => $is_passing,
              details => \@details,
              log     => $output };
}

=head2 freeze_builder

  Arg [1]    : Coderef for tests
  Example    : my $b = freeze_builder( Test::More->builder() );
  Description: Freeze the builder so it can be restored once a test has been run
  Returntype : copy of builder status
  Exceptions : none
  Caller     : run_test
  Status     : Stable

=cut
sub freeze_builder {
  my ($builder) = @_;
  my $copy = {};
  for my $k ( keys %$builder ) {
    $copy->{$k} = copy( $builder->{$k} );
  }
  return $copy;
}
=head2 copy

  Arg [1]    : Object to copy
  Example    : my $c = copy($o);
  Description: Perform deep copy on an object
  Returntype : Object copy
  Exceptions : none
  Caller     : freeze_builder
  Status     : Stable

=cut
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
=head2 restore_builder

  Arg [1]    : Builder to restore
  Arg [2]    : Hashref of state
  Example    : restore_builder( Test::More->builder(), $b );
  Description: Restore a Test::More builder to its previous state
  Returntype : none
  Exceptions : none
  Caller     : run_test
  Status     : Stable

=cut
sub restore_builder {
  my ( $builder, $settings ) = @_;
  while ( my ( $k, $v ) = each %$settings ) {
    $builder->{$k} = $v;
  }
  return;
}

1;
