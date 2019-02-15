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

package Bio::EnsEMBL::DataCheck::Checks::SpeciesTaxonomy;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SpeciesTaxonomy',
  DESCRIPTION => 'Taxonomic meta keys are consistent with taxonomy database',
  GROUPS      => ['core', 'meta'],
  DB_TYPES    => ['core'],
  TABLES      => ['meta']
};

sub tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");

  my $taxon_id = $mca->single_value_by_key('species.taxonomy_id');
  my $sci_name = $mca->single_value_by_key('species.scientific_name');

  # In collection dbs, sometimes the accession is added to the
  # scientific name, to disambiguate in the case of multiple strains
  # or assemblies of the same species.
  $sci_name =~ s/ \(GCA_\d+\)//;

  my $desc_1 = 'Species-related meta data exists';
  ok(defined $taxon_id && defined $sci_name, $desc_1);

  if (defined $taxon_id && defined $sci_name) {
    my $desc_2 = "Species name correct for taxonomy ID ($taxon_id)";

    my $taxonomy_dba = $self->registry->get_DBAdaptor('multi', 'taxonomy');
    my $tna  = $taxonomy_dba->get_TaxonomyNodeAdaptor();
    my $node = $tna->fetch_by_taxon_id($taxon_id);
    is($sci_name, $node->name, $desc_2);
  }
}

1;
