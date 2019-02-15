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

package Bio::EnsEMBL::DataCheck::Checks::SchemaType;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SchemaType',
  DESCRIPTION => 'The schema type meta key matches the DB name',
  GROUPS      => ['compara', 'core', 'corelike', 'funcgen', 'schema', 'variation'],
  DB_TYPES    => ['cdna', 'compara', 'core', 'funcgen', 'otherfeatures', 'rnaseq', 'variation'],
  TABLES      => ['meta'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");
  my $schema_types = $mca->list_value_by_key('schema_type');

  # We don't use the 'single_value_by_key' method because that throws
  # an error if more than one is found. Checking the count ourselves is
  # cleaner, it avoids messy error capturing.
  my $desc_1 = 'One schema_type meta key';
  is(scalar(@$schema_types), 1, $desc_1);

  if (scalar(@$schema_types) == 1) {
    my $db_type = $self->dba->group;
    if ($db_type =~ /(cdna|otherfeatures|rnaseq)/) {
      $db_type = 'core';
    }
    my $desc_2 = "Meta key schema_type matches the type of database";
    is($$schema_types[0], $db_type, $desc_2);
  }
}

1;

