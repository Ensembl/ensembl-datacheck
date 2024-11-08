=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

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
  DESCRIPTION => 'Check Metakey species.production_name is same as organism.production_name',
  GROUPS      => ['core'],
  DB_TYPES    => ['core'],
  TABLES      => ['meta']
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;
  my $group = $self->dba->group;
  my $sql = qq/
    SELECT meta_key, meta_value FROM meta
    WHERE species_id = $species_id AND 
    meta_key in ('species.production_name', 'organism.production_name')
    /;

  my $helper = $self->dba->dbc->sql_helper;
  my %meta_keys = %{ $helper->execute_into_hash(-SQL => $sql)};
  my $desc = 'Metakeys species.production_name should be same as organism.production_name'
  cmp_ok($meta_keys{'species.production_name'}, '==', $meta_keys{'organism.production_name'}, $desc);
}

1;
