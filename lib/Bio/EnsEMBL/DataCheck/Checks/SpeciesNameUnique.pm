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

=cut

package Bio::EnsEMBL::DataCheck::Checks::SpeciesNameUnique;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SpeciesNameUnique',
  DESCRIPTION => 'Species production_name and alias are unique across all databases in the registry',
  GROUPS      => ['core', 'meta'],
  DB_TYPES    => ['core'],
  TABLES      => ['meta'],
  PER_DB      => 1,
};

sub tests {
  my ($self) = @_;

  # The test currently allows for a species.alias that is the same as
  # species.production_name. This is redundant, but doesn't hurt.
  # If we want to fail in such cases, remove the 'DISTINCT' below.
  my $sql = qq/
    SELECT DISTINCT meta_value, species_id FROM meta
    WHERE
      (meta_key = 'species.production_name' OR
       meta_key = 'species.alias')
  /;

  # First, test if species is unique within the database.
  my $helper = $self->dba->dbc->sql_helper;
  my $names = $helper->execute(-SQL => $sql);
  $self->dba->dbc && $self->dba->dbc->disconnect_if_idle();

  my %names;
  foreach (@$names) {
    my ($name, undef) = @{$_};
    $names{$name}++;
  }
  foreach my $name (sort keys %names) {
    my $desc = "Species name $name is unique within database";
    is($names{$name}, 1, $desc);
  }

  # Second, check if species appears in any database in the given registry.
  # For this check to be meaningful, that registry needs to have between
  # defined with all of the appropriate species.
  my %all_names;
  my %dbs;
  my $all_dbas = $self->registry->get_all_DBAdaptors(-GROUP => 'core');
  foreach my $dba (@$all_dbas) {
    my $dbname = $dba->dbc->dbname;
    next if exists $dbs{$dbname};
    $dbs{$dbname}++;

    $helper = $dba->dbc->sql_helper;
    my $all_names = $helper->execute(-SQL => $sql);
    $dba->dbc && $dba->dbc->disconnect_if_idle();

    foreach (@$all_names) {
      my ($name, undef) = @{$_};
      push @{ $all_names{$name} }, $dbname;
    }
  }

  foreach my $name (sort keys %names) {
    my $desc = "Species name $name is unique across databases";
    is(scalar @{ $all_names{$name} }, 1, $desc) or
      diag("In multiple databases: " . join(", ", @{ $all_names{$name} }));
  }
}

1;
