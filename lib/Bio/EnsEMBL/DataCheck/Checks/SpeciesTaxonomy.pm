=head1 LICENSE

Copyright [2018-2022] EMBL-European Bioinformatics Institute

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
  GROUPS      => ['core', 'brc4_core', 'meta'],
  DB_TYPES    => ['core'],
  TABLES      => ['meta']
};

sub tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");

  my $taxon_id    = $mca->single_value_by_key('species.taxonomy_id');
  my $sp_taxon_id = $mca->single_value_by_key('species.species_taxonomy_id');
  my $sci_name    = $mca->single_value_by_key('species.scientific_name');
  my $strain      = $mca->single_value_by_key('species.strain');

  # In collection dbs, sometimes a strain or the accession is added to the
  # scientific name, to disambiguate in the case of multiple strains
  # or assemblies of the same species. Since the taxonomy database does
  # not always have that information, remove it before comparing.
  $sci_name =~ s/ \(GCA_\d+\)//;
  $sci_name =~ s/ (str\.|strain) .*//;

  my $desc_1 = 'Species-related meta data exists';
  ok(defined $taxon_id && defined $sci_name, $desc_1);

  if (defined $taxon_id && defined $sci_name) {
    my $desc_2 = "Taxonomy ID ($taxon_id) for $sci_name is valid";
    my $desc_3 = "Species name correct for taxonomy ID ($taxon_id)";

    my $taxonomy_dba = $self->get_dba('multi', 'taxonomy');

    my $desc_exists = "Taxonomy database found";
    if ( ok(defined $taxonomy_dba, $desc_exists) ) {
      my $tna = $taxonomy_dba->get_TaxonomyNodeAdaptor();
      my $node = $tna->fetch_by_taxon_id($taxon_id);
      ok(defined $node, $desc_2);

      if (defined $node) {
        # For species in the NCBI taxonomy that have strain details,
        # we typically split that out into a separate meta_key.
        # So we remove that here, if necessary. 
        my $tax_name = $node->name;
        if ($sci_name ne $tax_name) {
          $tax_name =~ s/$strain// if defined $strain;
          $tax_name =~ s/ (str\.|strain) .*//;
          $tax_name =~ s/ $//;
        }

        my $alias = 0;

        if ($sci_name ne $tax_name) {
          my @synonyms = ();
          my $synonyms = $node->names->{'synonym'};
          my $includes = $node->names->{'includes'};
          my $genbank_synonyms = $node->names->{'genbank synonym'};
          my $equivalent_names = $node->names->{'equivalent name'};
          push @synonyms, @{$synonyms} if defined $synonyms;
          push @synonyms, @{$includes} if defined $includes;
          push @synonyms, @{$genbank_synonyms} if defined $genbank_synonyms;
          push @synonyms, @{$equivalent_names} if defined $equivalent_names;

          foreach my $synonym (@synonyms) {
            if ($sci_name ne $synonym) {
              $synonym =~ s/$strain// if defined $strain;
              $synonym =~ s/ (str\.|strain) .*//;
              $synonym =~ s/ $//;
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

      if (defined $sp_taxon_id) {
        my $desc_4 = "Species Taxonomy ID ($sp_taxon_id) is valid";
        my $desc_5 = "Species Taxonomy ID ($sp_taxon_id) is at 'species' level";
        my $sp_node = $tna->fetch_by_taxon_id($sp_taxon_id);
        ok(defined $sp_node, $desc_4);
        is($sp_node->rank, 'species', $desc_5);
      }
    }
  }
}

1;
