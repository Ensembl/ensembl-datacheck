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

package Bio::EnsEMBL::DataCheck::Checks::SchemaVersion;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SchemaVersion',
  DESCRIPTION => 'The schema version meta key matches the DB name',
  GROUPS      => ['ancestral', 'brc4_core', 'compara', 'compara_homology_annotation', 'core', 'corelike', 'funcgen', 'schema', 'variation'],
  DB_TYPES    => ['cdna', 'compara', 'core', 'funcgen', 'otherfeatures', 'rnaseq', 'variation'],
  TABLES      => ['meta'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");
  my $schema_version = $mca->schema_version;

  my $db_version;
  if ($self->dba->group eq 'compara' || $self->dba->dbc->dbname =~ /ancestral/) {
    ($db_version) = $self->dba->dbc->dbname =~ /(\d+)$/;
  } else {
    ($db_version) = $self->dba->dbc->dbname =~ /(\d+)_\d+$/;
  }

  my $desc = "Meta key schema_version matches version in database name";
  is($schema_version, $db_version, $desc);
}

1;
