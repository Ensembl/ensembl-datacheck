=head1 LICENSE

Copyright [2018-2025] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::DatabaseSpeciesName;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'DatabaseSpeciesName',
  DESCRIPTION    => 'The species.production_name meta key matches the DB name',
  GROUPS         => ['core', 'corelike', 'funcgen', 'meta', 'variation'],
  DB_TYPES       => ['cdna', 'core', 'funcgen', 'otherfeatures', 'rnaseq', 'variation'],
  TABLES         => ['meta'],
  PER_DB         => 1
};

sub skip_tests {
  my ($self) = @_;

  if ( $self->dba->is_multispecies ) {
    return (1, 'Names not expected to match for collection databases.');
  }
}

sub tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");
  my $species_name = $mca->single_value_by_key('species.production_name');
  my $db_type = $self->dba->group;
  my ($db_species_name) = $self->dba->dbc->dbname =~ /^(.+)_${db_type}_/;

  my $desc = "Meta key species.production_name matches first part of database name";
  is($species_name, $db_species_name, $desc);
}

1;
