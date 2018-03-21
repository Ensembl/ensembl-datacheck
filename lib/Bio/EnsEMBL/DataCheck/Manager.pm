=head1 LICENSE

Copyright [2018] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the 'License');
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an 'AS IS' BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 NAME

Bio::EnsEMBL::DataCheck::Manager;

=cut

package Bio::EnsEMBL::DataCheck::Manager;

use warnings;
use strict;
use feature 'say';

use JSON;
use List::Util qw/any/;
use Moose;
use Path::Tiny;
use TAP::Harness;

use Bio::EnsEMBL::DataCheck::SourceHandler;

=head2 datacheck_dir
  Description: Path to directory of datacheck modules.
=cut
has 'datacheck_dir' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
  builder  => '_datacheck_dir_default',
);

sub _datacheck_dir_default {
  (my $module_name = __PACKAGE__) =~ s!::!/!g;
  my $dir = $INC{"$module_name.pm"};

  $dir =~ s![\w\.]+$!Checks!;

  die "Cannot find directory: $dir" unless -d $dir;

  return $dir;
}

=head2 names
  Description: List of datacheck names
=cut
has 'names' => (
  is      => 'rw',
  isa     => 'ArrayRef[Str]',
  default => sub { [] }
);

=head2 patterns
  Description: List of patterns to match against names and descriptions
=cut
has 'patterns' => (
  is      => 'rw',
  isa     => 'ArrayRef[Str]',
  default => sub { [] }
);

=head2 groups
  Description: List of datacheck groups
=cut
has 'groups' => (
  is      => 'rw',
  isa     => 'ArrayRef[Str]',
  default => sub { [] }
);

=head2 datacheck_types
  Description: List of datacheck types
=cut
has 'datacheck_types' => (
  is      => 'rw',
  isa     => 'ArrayRef[Str]',
  default => sub { [] }
);

=head2 history_file
  Description: Path to a file with results from a previous datacheck run
=cut
has 'history_file' => (
  is  => 'rw',
  isa => 'Str | Undef',
);

sub run_checks {
  my $self = shift;

  my $datachecks = $self->load_checks(@_);

  my $harness = TAP::Harness->new( { verbosity => 1 } );
  my $aggregator = $harness->runtests(map { [ $_, $_->name ] } @$datachecks);

  if (defined $self->history_file) {
    $self->write_history($datachecks, $self->history_file, 1);
  }

  return ($datachecks, $aggregator);
}

sub load_checks {
  my $self = shift;
  my @params = @_;

  my $dir = path($self->datacheck_dir);

  my @datacheck_files = $dir->children( qr/\.pm$/ );

  my $filters =
    scalar(@{$self->names}) ||
    scalar(@{$self->patterns}) ||
    scalar(@{$self->groups}) ||
    scalar(@{$self->datacheck_types});

  my @datachecks;

  foreach (@datacheck_files) {
    eval { require $_ };
    die $@ if $@;

    my ($package_name) = $_->slurp =~ /^package\s*([^;]+)/m;
    my $datacheck = $package_name->new(@params);

    if (!$filters || $self->filter($datacheck)) {
      push @datachecks, $datacheck;
    }
  }

  if (defined $self->history_file) {
    $self->read_history(\@datachecks, $self->history_file);
  }

  return \@datachecks;
}

sub filter {
  my $self = shift;
  my ($datacheck) = @_;

  if (any { $datacheck->name eq $_ } @{$self->names}) {
    return 1;
  }

  if (any { $datacheck->name =~ /$_/ } @{$self->patterns}) {
    return 1;
  }

  if (any { $datacheck->description =~ /$_/i } @{$self->patterns}) {
    return 1;
  }

  foreach my $group (@{$datacheck->groups}) {
    if (any { $group eq $_ } @{$self->groups}) {
      return 1;
    }
  }

  if (any { $datacheck->datacheck_type eq $_ } @{$self->datacheck_types}) {
    return 1;
  }
}

sub read_history {
  my $self = shift;
  my ($datachecks, $history_file) = @_;

  my %history = ();

  if (-s $history_file) {
    # slurp gets an exclusive lock on the file before reading it.
    my $json = path($history_file)->slurp;
    %history = %{ JSON->new->decode($json) };

    foreach (@$datachecks) {
      my $name = $_->name;
      my $result;

      if ($_->isa('Bio::EnsEMBL::DataCheck::DbCheck')) {
        my $host   = $_->dba->dbc->host;
        my $port   = $_->dba->dbc->port;
        my $dbname = $_->dba->dbc->dbname;

        if ($_->per_species) {
          my $species_id = $_->dba->species_id;
          $result = $history{"$host:$port"}{$dbname}{$species_id}{$name};
        } else {
          $result = $history{"$host:$port"}{$dbname}{'all'}{$name};
        }
      } elsif (exists $history{$name}) {
        $result = $history{$name};
      }

      $_->_started($$result{'started'});
      $_->_finished($$result{'finished'});
      $_->_passed($$result{'passed'});
    }
  }

  return \%history;
}

sub write_history {
  my $self = shift;
  my ($datachecks, $history_file, $overwrite) = @_;

  if (!defined $history_file) {
    die "Path to history file not specified";
  }

  if (-s $history_file && !$overwrite) {
    die "'$history_file' exists, and will not be overwritten";
  }

  my %history;
  if (-s $history_file) {
    # We read the data from file again, which will pick up and thus
    # preserve any changes that have been written by other Managers
    # that finished running after the current Manager instance was created.
    %history = %{ $self->read_history([], $history_file) };
  }

  foreach my $datacheck (@$datachecks) {
    my $name   = $datacheck->name;
    my $result = {
      'started'  => $datacheck->_started,
      'finished' => $datacheck->_finished,
      'passed'   => $datacheck->_passed * 1,
    };

    if ($datacheck->isa('Bio::EnsEMBL::DataCheck::DbCheck')) {
      my $host   = $datacheck->dba->dbc->host;
      my $port   = $datacheck->dba->dbc->port;
      my $dbname = $datacheck->dba->dbc->dbname;

      if ($datacheck->per_species) {
        my $species_id = $datacheck->dba->species_id;
        $history{"$host:$port"}{$dbname}{$species_id}{$name} = $result;
      } else {
        $history{"$host:$port"}{$dbname}{'all'}{$name} = $result;
      }
    } else {
      $history{$name} = $result;
    }
  }

  # spew gets an exclusive lock on the file before reading it.
  my $json = JSON->new->pretty->encode(\%history);
  path($history_file)->spew($json);

  return \%history;
}

1;
