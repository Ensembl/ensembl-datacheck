=head1 LICENSE

Copyright [2018-2019] EMBL-European Bioinformatics Institute

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

=head2 index_file
  Description: Path to a file with datacheck meta data
=cut
has 'index_file' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
  builder  => '_index_file_default',
);

sub _index_file_default {
  (my $module_name = __PACKAGE__) =~ s!::!/!g;
  my $file = $INC{"$module_name.pm"};

  $file =~ s![\w\.]+$!index.json!;

  die "Cannot find index_file: $file" unless -e $file;

  return $file;
}

=head2 config_file
  Description: Path to a file with parameters needed by datachecks
=cut
has 'config_file' => (
  is       => 'rw',
  isa      => 'Str | Undef',
  lazy     => 1,
  required => 0,
  builder  => '_config_file_default',
);

sub _config_file_default {
  (my $module_name = __PACKAGE__) =~ s!::!/!g;
  my $file = $INC{"$module_name.pm"};

  $file =~ s!lib/Bio/EnsEMBL/DataCheck/[\w\.]+$!config.json!;

  return $file if -e $file;
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
  Description: Path to a file with details from a previous datacheck run
=cut
has 'history_file' => (
  is  => 'rw',
  isa => 'Str | Undef',
);

=head2 output_file
  Description: Path to a file in which to store TAP format output from tests
=cut
has 'output_file' => (
  is  => 'rw',
  isa => 'Str | Undef',
);

=head2 overwrite_files
  Description: By default, index_file, history_file and output_file will be overwritten
=cut
has 'overwrite_files' => (
  is      => 'rw',
  isa     => 'Bool',
  default => 1
);

__PACKAGE__->meta->make_immutable;

sub load_config {
  my $self = shift;
  my %params = @_;

  if (defined $self->config_file) {
    die "Config file does not exist" unless -e $self->config_file;

    my $json = path($self->config_file)->slurp;
    my %config = %{ JSON->new->decode($json) };

    foreach my $key (keys %config) {
      if (!exists $params{$key}) {
        $params{$key} = $config{$key};
      }
    }
  }

  return %params;
}

sub load_checks {
  my $self = shift;
  my @params = $self->load_config(@_);

  my %index = %{ $self->read_index() };

  my $filters =
    scalar( @{$self->names}           ) ||
    scalar( @{$self->patterns}        ) ||
    scalar( @{$self->groups}          ) ||
    scalar( @{$self->datacheck_types} );

  my @datachecks;

  foreach my $name (sort keys %index) {
    if (!$filters || $self->filter($index{$name})) {
      my $module = path($self->datacheck_dir, "$name.pm");

      eval { require $module };
      die $@ if $@;

      my $datacheck = $index{$name}{package_name}->new(@params);

      push @datachecks, $datacheck;
    }
  }

  if (defined $self->history_file) {
    $self->read_history(\@datachecks);
  }

  return \@datachecks;
}

sub filter {
  my $self = shift;
  my ($meta_data) = @_;

  if (any { $$meta_data{name} eq $_ } @{$self->names}) {
    return 1;
  }

  if (any { $$meta_data{name} =~ /$_/ } @{$self->patterns}) {
    return 1;
  }

  if (any { $$meta_data{description} =~ /$_/i } @{$self->patterns}) {
    return 1;
  }

  foreach my $group ( @{$$meta_data{groups}} ) {
    if (any { $group eq $_ } @{$self->groups}) {
      return 1;
    }
  }

  if (any { $$meta_data{datacheck_type} eq $_ } @{$self->datacheck_types}) {
    return 1;
  }
}

sub run_checks {
  my $self = shift;
  my @params = @_;

  my $datachecks = $self->load_checks(@params);

  my $STDOUT_COPY;

  my $output_file = $self->output_file;
  if (defined $output_file) {
    if (-s $output_file) {
      unless ($self->overwrite_files) {
        die "'$output_file' exists, and will not be overwritten";
      }
    } else {
      path($output_file)->parent->mkpath;
    }

	# Copy STDOUT to another filehandle
	open($STDOUT_COPY, '>&', STDOUT);
    open(STDOUT, '>', $output_file);
  }

  my $harness = TAP::Harness->new( { verbosity => 1 } );
  my $aggregator = $harness->runtests(map { [ $_, $_->name ] } @$datachecks);

  if (defined $output_file) {
    # Restore STDOUT
    open(STDOUT, '>&', $STDOUT_COPY);
  }

  if (defined $self->history_file) {
    $self->write_history($datachecks);
  }

  return ($datachecks, $aggregator);
}

sub read_index {
  my $self = shift;

  my %index = ();

  if (-s $self->index_file) {
    my $json = path($self->index_file)->slurp;
    %index = %{ JSON->new->decode($json) };
  }

  return \%index;
}

sub write_index {
  my $self = shift;

  my %index;
  if (-s $self->index_file) {
    unless ($self->overwrite_files) {
      die $self->index_file . " exists, and will not be overwritten";
    }
  } else {
    path($self->index_file)->parent->mkpath;
  }

  my $dir = path($self->datacheck_dir);

  my @datacheck_files = $dir->children( qr/\.pm$/ );

  foreach (@datacheck_files) {
    eval { require $_ };
    die $@ if $@;

    my ($package_name) = $_->slurp =~ /^package\s*([^;]+)/m;
    my $datacheck = $package_name->new();

    $index{$datacheck->name} = {
      package_name   => $package_name,
      name           => $datacheck->name,
      description    => $datacheck->description,
      groups         => $datacheck->groups,
      datacheck_type => $datacheck->datacheck_type,
    };
  }

  my $json = JSON->new->canonical->pretty->encode(\%index);
  path($self->index_file)->spew($json);

  return \%index;
}

sub read_history {
  my $self = shift;
  my ($datachecks) = @_;
  $datachecks = [] unless defined $datachecks;

  my %history = ();

  if (-s $self->history_file) {
    # slurp gets an exclusive lock on the file before reading it.
    my $json = path($self->history_file)->slurp;
    %history = %{ JSON->new->decode($json) };

    foreach (@$datachecks) {
      my $name = $_->name;
      my $result;

      if ($_->isa('Bio::EnsEMBL::DataCheck::DbCheck')) {
        my $host   = $_->dba->dbc->host;
        my $port   = $_->dba->dbc->port;
        my $dbname = $_->dba->dbc->dbname;

        if (! $_->per_db) {
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
  my ($datachecks) = @_;
  $datachecks = [] unless defined $datachecks;

  if (!defined $self->history_file) {
    die "Path to history file not specified";
  }

  my %history;
  if (-s $self->history_file) {
    unless ($self->overwrite_files) {
      die $self->history_file . " exists, and will not be overwritten";
    }

    # We read the data from file again, which will pick up and thus
    # preserve any changes that have been written by other Managers
    # that finished running after the current Manager instance was created.
    %history = %{ $self->read_history() };
  } else {
    path($self->history_file)->parent->mkpath;
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

      if (! $datacheck->per_db) {
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
  path($self->history_file)->spew($json);

  return \%history;
}

1;
