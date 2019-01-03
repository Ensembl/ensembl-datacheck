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
 use Time::HiRes qw( usleep );
extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SpeciesNameUnique',
  DESCRIPTION => 'Check that production_name and alias are unique across all species',
  GROUPS      => ['meta'],
  DB_TYPES    => ['core'],
  TABLES      => ['meta'],
};

sub tests {
  my ($self) = @_;

  my %names;
  my $sql = qq/
    SELECT DISTINCT meta_value FROM meta
    WHERE
      (meta_key = 'species.production_name' OR
       meta_key = 'species.alias') AND
      species_id = ?
  /;

  my $all_dbas = $self->registry->get_all_DBAdaptors(-GROUP => 'core');
  foreach my $dba (@$all_dbas) {
    my $helper = $dba->dbc->sql_helper;
    my $dbname = $dba->dbc->dbname;

    my $names = $helper->execute_simple(-SQL => $sql, -PARAMS => [$dba->species_id]);
    map { push @{ $names{$_} }, $dbname } @$names;

    $dba->dbc && $dba->dbc->disconnect_if_idle();
  }

  foreach my $name (sort keys %names) {
    my $desc = "Species name $name is unique";
    is(scalar @{ $names{$name} }, 1, $desc) or
      diag("In multiple databases: " . join(", ", @{ $names{$name} }));
  }
}

1;
