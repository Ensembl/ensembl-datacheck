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
Bio::EnsEMBL::DataCheck::DbCheck

=head1 DESCRIPTION
A datacheck that requires a DBAdaptor object.

=cut

package Bio::EnsEMBL::DataCheck::DbCheck;

use strict;
use warnings;
use feature 'say';

use List::Util qw/any/;
use Moose;
use Moose::Util::TypeConstraints;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::BaseCheck';

use constant {
  DB_TYPES => undef,
  TABLES   => undef,
  PER_DB   => undef,
};

subtype 'DBAdaptor', as 'Object', where {
   $_->isa('Bio::EnsEMBL::DBSQL::DBAdaptor') || 
   $_->isa('Bio::EnsEMBL::Compara::DBSQL::DBAdaptor') || 
   $_->isa('Bio::EnsEMBL::Funcgen::DBSQL::DBAdaptor') || 
   $_->isa('Bio::EnsEMBL::Variation::DBSQL::DBAdaptor')
};

=head1 METHODS

=head2 db_types
  Description: Database types for which this datacheck is appropriate.
=cut
has 'db_types' => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub { [] }
);

=head2 tables
  Description: Tables containing data that is part of this datacheck.
=cut
has 'tables' => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub { [] }
);

=head2 per_db
  Description: If 1, the tests can safely be run once for a whole database,
               rather than once per species (only relevant for collection dbs).
=cut
has 'per_db' => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0
);

=head2 dba
  Description: DBAdaptor object for database on which to run tests.
=cut
has 'dba' => (
  is  => 'rw',
  isa => 'DBAdaptor | Undef',
);

# Set the read-only parameters just before 'new' method is called.
# This ensures that these values can be constants in the subclasses,
# while avoiding the need to overwrite the 'new' method (which would
# affect immutability).
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;
  my %param = @_;

  die "'db_types' cannot be overridden" if exists $param{db_types};
  die "'tables' cannot be overridden" if exists $param{tables};
  die "'per_species' cannot be overridden" if exists $param{per_species};

  $param{db_types} = $class->DB_TYPES if defined $class->DB_TYPES;
  $param{tables}   = $class->TABLES if defined $class->TABLES;
  $param{per_db}   = $class->PER_DB if defined $class->PER_DB;

  return $class->$orig(%param);
};

before 'run' => sub {
  my $self = shift;

  if (!defined $self->dba) {
    die "DBAdaptor must be set as 'dba' attribute";
  }
};

after 'run' => sub {
  my $self = shift;

  $self->dba->dbc && $self->dba->dbc->disconnect_if_idle();
};

sub run_tests {
  my $self = shift;

  if (!$self->per_db && $self->dba->is_multispecies) {
    # We cannot change the species of an established DBA; but we
    # can get it to give us a list of species, and then create
    # a new DBA (reusing the same connection) for each species in turn.
    my $original_dba = $self->dba;

    foreach my $species (@{$self->dba->all_species}) {
      my $dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
        -dbconn         => $original_dba->dbc,
        -species        => $species,
        -add_species_id => 1,
      );
      $self->dba($dba);

      subtest $self->dba->species => sub {
        $self->tests(@_);
      };
    }

    # It really shouldn't matter if we don't reset to the original
    # DBA. But it can't hurt either, and seems the right thing to do.
    $self->dba($original_dba);
  } else {
    $self->tests(@_);
  }
}

sub skip_datacheck {
  my $self = shift;

  my ($skip, $skip_reason) = $self->verify_db_type();
  if (!$skip) {
    ($skip, $skip_reason) = $self->check_history();
    if (!$skip) {
      ($skip, $skip_reason) = $self->skip_tests(@_);
    }
  }

  return ($skip, $skip_reason);
}

sub verify_db_type {
  my $self = shift;

  # If no db_types are specified, assume that it is fine
  # to run on all databases; otherwise, the dba group
  # must match one of the given db_types.
  if (scalar(@{$self->db_types}) > 0) {
    my $db_type = $self->dba->group;
    if (! any { $db_type eq $_ } @{$self->db_types}) {
      return (1, "Database type '$db_type' is not relevant for this datacheck");
    }
  }

  return;
}

sub check_history {
  my $self = shift;

  my $run_required = 1;

  if ($self->_passed && $self->_started) {
    my $tables_in_db = $self->table_dates();
    my @tables_to_check;

    # If no tables are specified, check them all.
    if (scalar(@{$self->tables}) == 0) {
      @tables_to_check = keys %$tables_in_db;
    } else {
      @tables_to_check = @{$self->tables};
    }

    $run_required = 0;
    foreach my $table_name (@tables_to_check) {
      if (exists $$tables_in_db{$table_name}) {
        if ($self->_started < $$tables_in_db{$table_name}) {
          $run_required = 1;
          last;
        }
      }
    }
  }

  if (!$run_required) {
    return (1, "Database tables not updated since last run");
  }

  return;
}

sub table_dates {
  my $self = shift;
  my $helper = $self->dba->dbc->sql_helper;

  # Return update_time in epoch format, to enable simple integer comparisons.
  my $sql = q/
    SELECT table_name, UNIX_TIMESTAMP(update_time)
    FROM information_schema.tables
    WHERE table_schema = database()
  /;

  return $helper->execute_into_hash(-SQL =>$sql);
}

sub skip_tests {
  # Method to be overridden by a subclass, if required.
}

1;
