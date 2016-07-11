package Bio::EnsEMBL::DataTest::BaseTest;
use Moose;
use Test::More;
use Test::Builder;
use Carp;
use Data::Dumper;

with 'MooseX::Log::Log4perl';

has 'name' => ( is => 'ro', isa => 'Str' );
has 'test' => ( is => 'ro', isa => 'CodeRef' );
# default test predicate allows a specific test to run specific predicate code
has 'test_predicate' => (
  is       => 'ro',
  isa      => 'CodeRef',
  required => 0,
  default  => sub {
    return sub { return { run => 1 } };
  } );

sub will_test {
  my ($self) = shift;
  return &{$self->test_predicate}(@_);
}

sub run {

  my $self = shift;
  # redirect output to a scalar
  my $output       = '';
  Test::More->builder()->output( \$output );
  Test::More->builder()->failure_output( \$output );

  # check to see if we're going to run this test
  my $will_test = $self->will_test( @_ );
  if ( $will_test->{run} != 1 ) {
    return { skipped => 1, reason => $will_test->{reason} };
  }

  # run the test code
  
  $self->test()->( @_ );

  # capture and return the results
  my @details = Test::More->builder()->details();
  my $res = { skipped => 0,
              pass    => Test::More->builder()->is_passing(),
              details => \@details,
              log     => $output };
  return $res;
} ## end sub run

1;
