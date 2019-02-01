=head1 LICENSE
Copyright [2018-2019] EMBL-European Bioinformatics Institute

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

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::URI qw/parse_uri/;
use DBI;
use List::Util qw/any/;
use Moose;
use Moose::Util::TypeConstraints;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::BaseCheck';

use constant {
  DB_TYPES => undef,
  TABLES   => undef,
  PER_DB   => undef,
  FORCE    => undef,
};

subtype 'DBAdaptor', as 'Object', where {
   $_->isa('Bio::EnsEMBL::DBSQL::DBAdaptor') || 
   $_->isa('Bio::EnsEMBL::Compara::DBSQL::DBAdaptor') || 
   $_->isa('Bio::EnsEMBL::Funcgen::DBSQL::DBAdaptor') || 
   $_->isa('Bio::EnsEMBL::Variation::DBSQL::DBAdaptor')
};

subtype 'Registry', as 'Str', where {
   $_ eq 'Bio::EnsEMBL::Registry'
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

=head2 force
  Description: If 1, the tests will always run, even if the datacheck detects
               that nothing has changed in the the database.
=cut
has 'force' => (
  is      => 'rw',
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

=head2 dba_species_only
  Description: Forces the datacheck to only run for a single species in a
               collection db, even if per_db is zero.
=cut
has 'dba_species_only' => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0
);

=head2 registry_file
  Description: Registry file used for finding databases that are needed
               for comparisons with the dba.
=cut
has 'registry_file' => (
  is  => 'ro',
  isa => 'Str | Undef',
);

=head2 server_uri
  Description: URI for a mysql server with databases that are needed for
               comparisons with the dba. Not used if registry_file is given.
=cut
has 'server_uri' => (
  is  => 'ro',
  isa => 'Str | Undef',
);

=head2 registry
  Description: Registry object, not instantiated unless necessary.
=cut
has 'registry' => (
  is      => 'rw',
  isa     => 'Registry | Undef',
  lazy    => 1,
  builder => '_registry_default',
);

sub _registry_default {
  my $self = shift;

  my $registry = 'Bio::EnsEMBL::Registry';

  # Our $self->dba is already in the registry; if we load from a file or
  # uri that also has it, we'll get two copies. So, we store the details of
  # the one we've already got, then remove it from the registry. Then, we
  # load the registry file/url, delete that species if it exists, then add
  # the original back, using the stored details. Easy (!)
  my $species = $self->species;

  my $uri = Bio::EnsEMBL::Utils::URI->new('mysql');
  $uri->host($self->dba->dbc->host);
  $uri->port($self->dba->dbc->port);
  $uri->user($self->dba->dbc->user);
  $uri->pass($self->dba->dbc->pass);
  $uri->db_params->{dbname} = $self->dba->dbc->dbname;
  $uri->add_param('group', $self->dba->group);
  $uri->add_param('species', $species);

  my $dba_url = $uri->generate_uri;

  $self->dba->dbc->disconnect_if_idle();

  if (defined $self->registry_file) {
    $registry->clear;
    $registry->load_all($self->registry_file);
  } elsif (defined $self->server_uri) {
    # We need species and group if dbname is given, to make sure
    # the registry manipulations we're about to do are valid.
    my $uri = parse_uri($self->server_uri);
    if ( $uri->db_params->{dbname} && $uri->db_params->{dbname} !~ /^(\d+)$/ ) {
      unless ($uri->param_exists_ci('species') && $uri->param_exists_ci('group')) {
        die "species and group parameters are required if the URI includes a database name";
      }
    }
    $registry->clear;
    $registry->load_registry_from_url($self->server_uri);
  } else {
    die "Registry requires a 'registry_file' or 'server_uri' attribute";
  }

  if ($registry->alias_exists($species)) {
	  $registry->remove_DBAdaptor($species, $self->dba->group);
  }

  $registry->load_registry_from_url($dba_url);
  $self->dba($registry->get_DBAdaptor($species, $self->dba->group));

  # Just in case the production_name is repeated as an alias.
  $registry->remove_alias($species, $species);

  return $registry;
}

=head2 old_server_uri
  Description: URI for a mysql server with old versions of databases for
               comparisons with the dba.
=cut
has 'old_server_uri' => (
  is  => 'ro',
  isa => 'Str | Undef',
);

=head2 data_file_path
  Description: Path to directory containing data files that need to be
               tested as part of some datachecks.
=cut
has 'data_file_path' => (
  is  => 'ro',
  isa => 'Str | Undef',
);

=head2 dba_list
  Description: List of DBAdaptor objects that get created by the datacheck.
               (They're tracked so that we can close the connections nicely.)
=cut
has 'dba_list' => (
  is      => 'rw',
  isa     => 'ArrayRef[DBAdaptor]',
  default => sub { [] }
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
  die "'force' cannot be overridden" if exists $param{force};

  $param{db_types} = $class->DB_TYPES if defined $class->DB_TYPES;
  $param{tables}   = $class->TABLES if defined $class->TABLES;
  $param{per_db}   = $class->PER_DB if defined $class->PER_DB;
  $param{force}    = $class->FORCE if defined $class->FORCE;

  return $class->$orig(%param);
};

before 'run' => sub {
  my $self = shift;

  if (defined $self->dba) {
    push @{$self->dba_list}, $self->dba;
  } else {
    die "DBAdaptor must be set as 'dba' attribute";
  }
};

after 'run' => sub {
  my $self = shift;

  foreach my $dba (@{ $self->dba_list }) {
    $dba->dbc && $dba->dbc->disconnect_if_idle();
  }
};

__PACKAGE__->meta->make_immutable;

sub load_registry {
  my $self = shift;
  $self->registry;
}

sub species {
  my $self = shift;
  my $mca = $self->dba->get_adaptor("MetaContainer");

  my $species;
  if ($self->dba->is_multispecies) {
    $species = $mca->single_value_by_key('species.db_name');
  } else {
    my $production_name = $mca->single_value_by_key('species.production_name');
    if (defined $production_name) {
      $species = $production_name;
    } else {
      $species = $self->dba->species;
    }
    $species =~ s/_old$//;
  }

  return $species;
}

sub get_dba {
  my $self = shift;
  my ($species, $group) = @_;

  $species = $self->species    unless defined $species;
  $group   = $self->dba->group unless defined $group;

  my $dba = $self->registry->get_DBAdaptor($species, $group);

  push @{$self->dba_list}, $dba if defined $dba;

  return $dba;
}

sub get_dna_dba {
  my $self = shift;

  $self->load_registry();
  my $dna_dba = $self->dba->dnadb();
  if ($dna_dba->group ne 'core') {
    die "Could not retrieve DNA database for ".$self->dba->dbc->dbname;
  }

  push @{$self->dba_list}, $dna_dba if defined $dna_dba;

  return $dna_dba;
}

sub get_old_dba {
  my $self = shift;
  my ($species, $group) = @_;

  $species = $self->species    unless defined $species;
  $group   = $self->dba->group unless defined $group;

  if (!defined $self->old_server_uri) {
    die "Old server details must be set as 'old_server_uri' attribute";
  }

  # At a minimum, old_server_uri will have server details. But it can
  # also define a db_version or a dbname. So, we check for a dbname first;
  # if we have one then we are more-or-less done; any parameters passed to
  # this method are irrelevant and are ignored. If there is a db_version,
  # use that, otherwise assume that it's the previous release.
  my $uri = parse_uri($self->old_server_uri);
  my %params = $uri->generate_dbsql_params();

  my $db_version;
  if (exists $params{'-DBNAME'}) {
    if ($params{'-DBNAME'} =~ /^(\d+)$/) {
      $db_version = $1;
      delete $params{'-DBNAME'};
    }
  } else {
    my $mca = $self->dba->get_adaptor("MetaContainer");
    $db_version = ($mca->schema_version) - 1;
  }

  my $dbh;
  if (exists $params{'-DBNAME'}) {
	my $message = 'Specified database does not exist';
	$dbh = $self->test_db_connection($uri, $params{'-DBNAME'}, $message);
  } else {
    my $meta_dba = $self->registry->get_DBAdaptor("multi", "metadata");
    die "No metadata database found in the registry" unless defined $meta_dba;

    my $helper = $meta_dba->dbc->sql_helper;
    my $sql = q/
      SELECT gd.dbname FROM 
        genome_database gd INNER JOIN
        genome g USING (genome_id) INNER JOIN
        organism o USING (organism_id) INNER JOIN
        data_release dr USING (data_release_id)
      WHERE gd.type = ? and o.name = ? and dr.ensembl_version = ?
    /;
    my $params = [$group, $species, $db_version];

    my @dbnames = @{$helper->execute_simple(-SQL => $sql, -PARAMS => $params)};

    if (scalar(@dbnames) == 1) {
      $params{'-DBNAME'} = $dbnames[0];
      my $message = 'Database in metadata database does not exist';
	  $dbh = $self->test_db_connection($uri, $params{'-DBNAME'}, $message);
    } elsif (scalar(@dbnames) > 1) {
      die "Multiple release $db_version $group databases for $species";
    }
  }

  # $old_dba can be undefined if there is no entry in the metadata db;
  # a datacheck could use the undefined-ness to skip tests in this case.
  my $old_dba;
  if (exists $params{'-DBNAME'}) {
    # We need to suffix '_old' to the species name to comply
    # with uniqueness rules, and ensure we can distinguish between the
    # two databases in the registry.
    $params{'-SPECIES'} = $species.'_old';
    $params{'-GROUP'}   = $group;

    # Because we have added a suffix to the species name,
    # the DBAdaptor code can't work out the correct species_id,
    # so we need to work out the species_id and pass it explicitly.
    my $sql = qq/
      SELECT species_id FROM meta
      WHERE
		meta_key = 'species.production_name' AND
		meta_value = '$species'
    /;
    my $vals = $dbh->selectcol_arrayref($sql);
    my $species_id = $vals->[0];
    $params{'-SPECIES_ID'} = $species_id;

	# We assume that if the new db is multispecies,
	# the old one will be too.
    if ($self->dba->is_multispecies) {
      $params{'-MULTISPECIES_DB'} = 1;
    }

	$old_dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(%params);

    push @{$self->dba_list}, $old_dba;
  }

  return $old_dba;
}

sub test_db_connection {
  my $self = shift;
  my ($uri, $dbname, $message) = @_;

  my $dsn = "DBI:mysql:database=$dbname;host=".$uri->host.";port=".$uri->port;
  my $dbh = DBI->connect($dsn, $uri->user, $uri->pass, { PrintError => 0 });

  if (! defined $dbh) {
    my $err = $DBI::errstr;
    die "$message: $dsn\n$err";
  }

  return $dbh;
}

sub run_datacheck {
  my $self = shift;

  if (!$self->per_db && !$self->dba_species_only && $self->dba->is_multispecies) {
    # We cannot change the species of an established DBA; but we
    # can get it to give us a list of species, and then create
    # a new DBA (reusing the same connection) for each species in turn.
    my $original_dba = $self->dba;

    # Fetch species_ids ourselves; the code in the DBAdaptor module doesn't
    # do it quite right, and doing it once for all is more efficient anyway.
    my $sql = qq/
      SELECT meta_value, species_id FROM meta
      WHERE meta_key = 'species.db_name'
    /;
    my $helper = $self->dba->dbc->sql_helper;
    my %species_ids = %{ $helper->execute_into_hash(-SQL => $sql) };

    foreach my $species (@{$self->dba->all_species}) {
      my $dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
        -dbconn          => $original_dba->dbc,
        -multispecies_db => 1,
        -species         => $species,
        -species_id      => $species_ids{$species},
      );
      $self->dba($dba);

      subtest $species => sub {
        SKIP: {
          my ($skip, $skip_reason) = $self->skip_tests(@_);

          plan skip_all => $skip_reason if $skip;

          $self->tests(@_);
        }
      };
    }

    # It really shouldn't matter if we don't reset to the original
    # DBA. But it can't hurt either, and seems the right thing to do.
    $self->dba($original_dba);

  } else {
    my $label = $self->species;
    if ($self->per_db && $self->dba->is_multispecies) {
      $label = 'all species in collection';
    }

    subtest $label => sub {
      SKIP: {
        my ($skip, $skip_reason) = $self->skip_tests(@_);

        plan skip_all => $skip_reason if $skip;

        $self->tests(@_);
      }
    }
  }
}

sub skip_datacheck {
  my $self = shift;

  my ($skip, $skip_reason) = $self->verify_db_type();
  if (!$skip) {
    ($skip, $skip_reason) = $self->check_history();
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

  if (!$self->force) {
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
