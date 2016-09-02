
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

Bio::EnsEMBL::DataTest::BaseTest

=head1 SYNOPSIS

 my $test = Bio::EnsEMBL::DataTest::BaseTest->new(
  name => "mytest",
  test => sub {
    ok( 1 == 1, "OK?" );
  } );
  
 my $results = $test->run();

=head1 DESCRIPTION

Base test class providing minimal methods.

=head1 METHODS

=cut

package Bio::EnsEMBL::DataTest::BaseTest;
use Moose;
use Data::Dumper;
use Bio::EnsEMBL::DataTest::Utils::TestUtils qw/run_test/;

with 'MooseX::Log::Log4perl';

=head2 name
  Description: Name of test
=cut
has 'name'        => ( is => 'ro', isa => 'Str' );

=head2 description
  Description: Brief description of test
=cut
has 'description' => ( is => 'ro', isa => 'Str' );

=head2 test
  Description: Test code
=cut
has 'test'        => ( is => 'ro', isa => 'CodeRef' );

=head2 test_predicate
  Description: Code to determine if test should be run. 
               Can be overridden to provide specific conditions.
=cut
has 'test_predicate' => (
  is       => 'ro',
  isa      => 'CodeRef',
  required => 0,
  default  => sub {
    return sub { return { run => 1 } };
  } );

=head2 will_test

  Arg [...]  : Arguments to pass to predicate
  Description: Code to invoke test predicate and return if test should be run
  Returntype : hashref (keys are 'run' and 'reason')
  Exceptions : None
  Caller     : general
  Status     : Stable

=cut
sub will_test {
  my ($self) = shift;
  return &{ $self->test_predicate }(@_);
}

=head2 run

  Arg [..]   : Arguments to pass to test method
  Description: Return the number of rows in a query 
  Returntype : hashref of results (keys are 'pass','details','skipped','reason')
  Exceptions : None
  Caller     : general
  Status     : Stable

=cut
sub run {

  my $self = shift;

  # check to see if we're going to run this test
  my $will_test = $self->will_test(@_);
  if ( $will_test->{run} != 1 ) {
    return { skipped => 1, reason => $will_test->{reason} };
  }

  my @args = @_;
  return run_test(
    sub {
      $self->test()->(@args);
    } );

}

1;
