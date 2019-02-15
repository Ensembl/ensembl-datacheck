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

package Bio::EnsEMBL::DataCheck::Checks::MetaKeyCardinality;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MetaKeyCardinality',
  DESCRIPTION => 'A subset of meta keys must only have a single value',
  GROUPS      => ['core', 'meta'],
  DB_TYPES    => ['core'],
  TABLES      => ['meta']
};

sub tests {
  my ($self) = @_;

  # There aren't keys which _must_ have multiple values; zero, one, or more
  # values are typically allowed, so we can only check for data that must be
  # single-valued.

  my @single_valued = qw/
    schema_type
    schema_version
    assembly.accession
    assembly.default
    genebuild.start_date
    genebuild.initial_release_date
    genebuild.last_geneset_update
    genebuild.version
    provider.name
    provider.url
    sample.gene_param
    sample.gene_text
    sample.location_param
    sample.location_text
    sample.search_text
    sample.transcript_param
    sample.transcript_text
    sample.variation_param
    sample.variation_text
    species.db_name
    species.display_name
    species.division
    species.production_name
    species.scientific_name
    species.species_name
    species.taxonomy_id
    species.url
  /;

  my $mca = $self->dba->get_adaptor("MetaContainer");

  foreach my $meta_key (@single_valued) {
    SKIP: {
      my $values = $mca->list_value_by_key($meta_key);

      skip "No meta_key $meta_key", 1 unless scalar @$values;

      my $desc = "Single value for meta_key $meta_key";
      is(@$values, 1, $desc);
    }
  }
}

1;

