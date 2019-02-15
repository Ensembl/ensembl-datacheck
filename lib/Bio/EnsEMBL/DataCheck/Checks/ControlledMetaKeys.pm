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

package Bio::EnsEMBL::DataCheck::Checks::ControlledMetaKeys;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ControlledMetaKeys',
  DESCRIPTION => 'Meta keys are consistent with production database',
  GROUPS      => ['controlled_tables', 'core', 'corelike', 'meta', 'funcgen', 'variation'],
  DB_TYPES    => ['cdna', 'core', 'funcgen', 'otherfeatures', 'rnaseq', 'variation'],
  TABLES      => ['meta']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;
  my $group = $self->dba->group;

  my $sql = qq/
    SELECT meta_key, COUNT(*) FROM meta
    WHERE species_id = $species_id OR species_id IS NULL
    GROUP BY meta_key
  /;
  my $helper = $self->dba->dbc->sql_helper;
  my %meta_keys = %{ $helper->execute_into_hash(-SQL => $sql) };

  my $prod_sql = qq/
    SELECT name, is_optional
    FROM meta_key
    WHERE FIND_IN_SET('$group', db_type) AND is_current = 1
  /;
  my $prod_dba    = $self->get_dba('multi', 'production');
  my $prod_helper = $prod_dba->dbc->sql_helper;
  my %prod_keys   = %{ $prod_helper->execute_into_hash(-SQL => $prod_sql) };

  foreach my $meta_key (keys %meta_keys) {
    my $desc = "Meta key '$meta_key' in production database";
    ok(exists $prod_keys{$meta_key}, $desc);
  }

  foreach my $meta_key (keys %prod_keys) {
    if (!$prod_keys{$meta_key}) {
      my $desc = "Mandatory meta key '$meta_key' exists";
      ok(exists $meta_keys{$meta_key}, $desc);
    }
  }
}

1;
