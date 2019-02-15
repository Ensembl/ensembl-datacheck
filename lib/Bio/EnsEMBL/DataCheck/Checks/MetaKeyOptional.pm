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

package Bio::EnsEMBL::DataCheck::Checks::MetaKeyOptional;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'MetaKeyOptional',
  DESCRIPTION    => 'Optional, but expected, meta keys exist',
  GROUPS         => ['core', 'meta'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['meta']
};

sub tests {
  my ($self) = @_;

  my @optional = qw/
    assembly.accession
    assembly.coverage_depth
    assembly.date
    assembly.ucsc_alias
    genebuild.id
    genebuild.initial_release_date
    genebuild.last_geneset_update
    genebuild.projection_source_db
    species.common_name
    species.stable_id_prefix
  /;

  my $mca = $self->dba->get_adaptor("MetaContainer");

  foreach my $meta_key (@optional) {
    my $values = $mca->list_value_by_key($meta_key);

    my $desc = "Value exists for meta_key $meta_key";
    ok(scalar @$values, $desc);
  }
}

1;
