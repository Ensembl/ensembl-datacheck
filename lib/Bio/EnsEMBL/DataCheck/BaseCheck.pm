=head1 LICENSE
Copyright [2018] EMBL-European Bioinformatics Institute

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
Bio::EnsEMBL::DataCheck::BaseCheck

=head1 DESCRIPTION
Base datacheck class providing minimal methods.

=cut

package Bio::EnsEMBL::DataCheck::BaseCheck;

use strict;
use warnings;
use feature 'say';

use Moose;
use Moose::Util::TypeConstraints;
use Test::More;

use constant {
  NAME           => undef,
  DESCRIPTION    => undef,
  GROUPS         => undef,
  DATACHECK_TYPE => undef,
};

=head1 METHODS

=head2 name
  Description: Name of datacheck.
=cut
has 'name' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1
);

=head2 description
  Description: Brief description of datacheck.
=cut
has 'description' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1
);

=head2 groups
  Description: Datachecks belong to zero or more groups. These can be
               conceptual ('gene-related') or pragmatic (e.g. 'handover').
=cut
has 'groups' => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub { [] }
);

=head2 datacheck_type
  Description: A datacheck can be "critical" (must not fail) or "advisory".
=cut
has 'datacheck_type' => (
  is      => 'ro',
  isa     => enum(['critical', 'advisory']),
  default => 'critical'
);

=head2 output
  Description: Once a datacheck has been run, TAP-formatted results are stored.
=cut
has 'output' => (
  is      => 'rw',
  isa     => 'Str | Undef',
);

has '_started' => (
  is  => 'rw',
  isa => 'Int | Undef',
);

has '_finished' => (
  is  => 'rw',
  isa => 'Int | Undef',
);

has '_passed' => (
  is  => 'rw',
  isa => 'Bool | Undef',
);

# Set the read-only parameters just before 'new' method is called.
# This ensures that these values can be constants in the subclasses,
# while avoiding the need to overwrite the 'new' method (which would
# affect immutability).
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;
  my %param = @_;

  die "'name' cannot be overridden" if exists $param{name};
  die "'description' cannot be overridden" if exists $param{description};
  die "'groups' cannot be overridden" if exists $param{groups};
  die "'datacheck_type' cannot be overridden" if exists $param{datacheck_type};

  $param{name}           = $class->NAME;
  $param{description}    = $class->DESCRIPTION;
  $param{groups}         = $class->GROUPS if defined $class->GROUPS;
  $param{datacheck_type} = $class->DATACHECK_TYPE if defined $class->DATACHECK_TYPE;

  return $class->$orig(%param);
};

sub skip_datacheck {
  # Method to be overridden by a subclass, if required.
}

sub run_tests {
  # Method can be overridden by a subclass, if required.
  my $self = shift;
  $self->tests(@_);
}

sub tests {
  die "'tests' method must be overridden by a subclass";
}

sub run {
  my $self = shift;
  my $name = $self->name;

  my $output = '';
  Test::More->builder->output(\$output);
  Test::More->builder->failure_output(\$output);

  subtest $name => sub {
    SKIP: {
      my ($skip, $skip_reason) = $self->skip_datacheck(@_);

      $self->_started(time);
      $self->_finished(undef);

      plan skip_all => $skip_reason if $skip;

      $self->run_tests(@_);

      $self->_finished(time);
    }
  };
  done_testing();

  # Need to explicitly erase the results, so that the aggregator doesn't
  # merge results with subsequent tests when run in a test harness.
  Test::More->builder->reset();

  # Store the output in the datacheck itself; this makes it easier to
  # get at later, without having to worry about if/where it's saved.
  $self->output($output);

  # Because all the tests associated with this datacheck are run as
  # subtests, there will always be a single test result in the TAP output.
  # It will be at the same level of indentation as the 'Subtest' header.
  my ($indent) = $output =~ /(\s*)# Subtest: $name/m;
  my $passed = $output =~ /^${indent}ok 1/m;
  $self->_passed($passed || 0);

  # Return value indicates failure, like a program exit code, i.e. 0 is fine.
  return $self->_passed ? 0 : 1;
}

1;
