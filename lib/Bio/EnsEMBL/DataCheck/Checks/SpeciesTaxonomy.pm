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
  my $strain   = $mca->single_value_by_key('species.strain');

  # In collection dbs, sometimes a strain or the accession is added to the
  # scientific name, to disambiguate in the case of multiple strains
  # or assemblies of the same species. Since the taxonomy database does
  # not always have that information, remove it before comparing.
  $sci_name =~ s/ \(GCA_\d+\)//;
  $sci_name =~ s/ str\. .*//;

  my $desc_1 = 'Species-related meta data exists';
  ok(defined $taxon_id && defined $sci_name, $desc_1);

  if (defined $taxon_id && defined $sci_name) {
    my $desc_2 = "Taxonomy ID ($taxon_id) for $sci_name is valid";
    my $desc_3 = "Species name correct for taxonomy ID ($taxon_id)";

    my $taxonomy_dba = $self->registry->get_DBAdaptor('multi', 'taxonomy');
    my $tna  = $taxonomy_dba->get_TaxonomyNodeAdaptor();

    my $node = $tna->fetch_by_taxon_id($taxon_id);
    ok(defined $node, $desc_2);

    if (defined $node) {
      # For species in the NCBI taxonomy that have strain details,
      # we typically split that out into a separate meta_key.
      # So we remove that here, if necessary. 
      my $tax_name = $node->name;
      if ($sci_name ne $tax_name) {
        $tax_name =~ s/ $strain// if defined $strain;
      }

      my $alias = 0;

      if ($sci_name ne $tax_name) {
        my @synonyms = ();
        my $synonyms = $node->names->{'synonym'};
        my $genbank_synonyms = $node->names->{'genbank synonym'};
        push @synonyms, @{$synonyms} if defined $synonyms;
        push @synonyms, @{$genbank_synonyms} if defined $genbank_synonyms;

        foreach my $synonym (@synonyms) {
          if ($sci_name ne $synonym) {
            $synonym =~ s/ $strain// if defined $strain;
          }

          if ($sci_name eq $synonym) {
            $tax_name = $synonym;
            $alias = 1;
            last;
          }
        }
      }
      is($sci_name, $tax_name, $desc_3);
      diag('Species name matches alias, not scientific name') if $alias;
    }
  }
}

1;
