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

package Bio::EnsEMBL::DataCheck::Checks::StrainGeneTreeSpeciesSets;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'StrainGeneTreeSpeciesSets',
  DESCRIPTION    => 'Strain-level gene-tree species sets are as expected',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_master'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => [
    'genome_db',
    'method_link',
    'method_link_species_set',
    'method_link_species_set_tag',
    'species_set',
    'species_set_header',
    'species_set_tag',
  ]
};


sub skip_tests {
  my ($self) = @_;
  my $compara_dba = $self->dba;
  my $mlss_dba = $compara_dba->get_MethodLinkSpeciesSetAdaptor();

  my @gene_tree_mlsses;
  foreach my $method_type ('PROTEIN_TREES', 'NC_TREES') {
    my $mlsses_of_type = $mlss_dba->fetch_all_by_method_link_type($method_type);
    my @curr_mlsses_of_type = grep { $_->is_current } @{$mlsses_of_type};
    push(@gene_tree_mlsses, @curr_mlsses_of_type);
  }

  if (scalar(@gene_tree_mlsses) == 0) {
    return( 1, sprintf("There are no current gene-tree MLSSes in %s", $compara_dba->dbc->dbname) );
  }
}


sub tests {
  my ($self) = @_;

  my $compara_dba = $self->dba;
  my $mlss_dba = $compara_dba->get_MethodLinkSpeciesSetAdaptor();
  my $species_set_dba = $compara_dba->get_SpeciesSetAdaptor();

  my @gene_tree_mlsses;
  foreach my $method_type ('PROTEIN_TREES', 'NC_TREES') {
    my $mlsses_of_type = $mlss_dba->fetch_all_by_method_link_type($method_type);
    my @curr_mlsses_of_type = grep { $_->is_current } @{$mlsses_of_type};
    push(@gene_tree_mlsses, @curr_mlsses_of_type);
  }

  my %species_sets_by_id;
  my %prefer_for_genome_map;
  foreach my $gene_tree_mlss (@gene_tree_mlsses) {
    my $gene_tree_species_set = $species_set_dba->fetch_by_dbID($gene_tree_mlss->species_set->dbID);
    $species_sets_by_id{$gene_tree_species_set->dbID} = $gene_tree_species_set;
    $prefer_for_genome_map{$gene_tree_species_set->dbID}{$gene_tree_mlss->dbID} = $gene_tree_mlss->get_value_for_tag('prefer_for_genomes', '');
  }

  my %strain_species_sets_by_id;
  my %non_strain_species_sets_by_id;
  while (my ($species_set_id, $gene_tree_species_set) = each %species_sets_by_id) {
    my @gdbs = @{$gene_tree_species_set->genome_dbs};
    my %gdb_name_set = map { $_->name => 1 } @gdbs;

    my %strain_group_breakdown;
    foreach my $gdb (@gdbs) {
      my $core_dba = $self->get_dba($gdb->name, 'core');
      my $meta_container = $core_dba->get_adaptor('MetaContainer');
      my $ref_gdb_name = $meta_container->single_value_by_key('species.strain_group', 0);
      next unless defined $ref_gdb_name && exists $gdb_name_set{$ref_gdb_name};
      $strain_group_breakdown{$ref_gdb_name} += 1;
    }

    my @ref_gdb_names = sort { $strain_group_breakdown{$b} <=> $strain_group_breakdown{$a} } keys %strain_group_breakdown;

    if (scalar(@ref_gdb_names) > 0) {
      my $consensus_ref_gdb_name = $ref_gdb_names[0];
      my $strain_count = $strain_group_breakdown{$consensus_ref_gdb_name};
      my $strain_count_threshold = 0.5 * $gene_tree_species_set->size;

      if ($strain_count >= $strain_count_threshold) {
        $strain_species_sets_by_id{$gene_tree_species_set->dbID} = $gene_tree_species_set;
      }
    }

    if (!exists $strain_species_sets_by_id{$gene_tree_species_set->dbID}) {
      $non_strain_species_sets_by_id{$gene_tree_species_set->dbID} = $gene_tree_species_set;
    }
  }

  # This list of known strain types should be kept in
  # sync with strain types in the StrainType datacheck.
  my @known_strain_types = (
      'strain',
      'breed',
      'cultivar',
      'ecotype',
      'haplotype',
      'isolate',
  );

  my $known_strain_type_patt = join('|', @known_strain_types);

  my %gdb_to_collection_name_set;
  my %gdb_to_preferred_collections;
  while (my ($species_set_id, $gene_tree_species_set) = each %strain_species_sets_by_id) {

    my $species_set_name = $gene_tree_species_set->name =~ s/^collection-//r;
    my $desc_1 = "Strain gene-tree species set '$species_set_name' has a strain_type tag";
    my $has_strain_type_tag = $gene_tree_species_set->has_tag('strain_type');
    ok($has_strain_type_tag, $desc_1);

    if ($has_strain_type_tag) {
      my $desc_2 = "Strain gene-tree species set '$species_set_name' has a known strain type";
      my $strain_type = $gene_tree_species_set->get_value_for_tag('strain_type');
      ok($strain_type =~ /^${known_strain_type_patt}$/, $desc_2);
    }

    foreach my $gdb (@{$gene_tree_species_set->genome_dbs}) {
      $gdb_to_collection_name_set{$gdb->name}{$species_set_name} = 1;
    }

    my $desc_5 = "Species set '$species_set_name' has consistent 'prefer_for_genome' MLSS tags";
    my %prefer_for_genome_tag_set = map { $_ => 1 } values %{$prefer_for_genome_map{$species_set_id}};
    my @prefer_for_genome_tags = keys %prefer_for_genome_tag_set;
    is(scalar(@prefer_for_genome_tags), 1, $desc_5)
      || diag explain [sort @prefer_for_genome_tags];

    my @preferred_for_genomes = split(/ /, $prefer_for_genome_tags[0]);
    foreach my $gdb_name (@preferred_for_genomes) {
      my $gdb_in_collection = exists $gdb_to_collection_name_set{$gdb_name}{$species_set_name};

      if ($gdb_in_collection) {
        $gdb_to_preferred_collections{$gdb_name}{$species_set_name} = 1;
      }

      my $desc_6 = "Genome '$gdb_name' is in preferred collection '$species_set_name'";
      ok($gdb_in_collection, $desc_6);
    }
  }

  foreach my $gdb_name (sort keys %gdb_to_collection_name_set) {
    my @species_sets_with_gdb = exists $gdb_to_preferred_collections{$gdb_name}
                              ? keys %{$gdb_to_preferred_collections{$gdb_name}}
                              : keys %{$gdb_to_collection_name_set{$gdb_name}}
                              ;

    my $desc_3 = "Genome '$gdb_name' can be assigned to one strain gene-tree species set";
    is(scalar(@species_sets_with_gdb), 1, $desc_3)
      || diag explain [sort @species_sets_with_gdb];
  }

  while (my ($species_set_id, $gene_tree_species_set) = each %non_strain_species_sets_by_id) {
    my $species_set_name = $gene_tree_species_set->name =~ s/^collection-//r;
    my $desc_4 = "Non-strain gene-tree species set '$species_set_name' is free of strain_type tags";
    my $lacks_strain_type_tag = !$gene_tree_species_set->has_tag('strain_type');
    ok($lacks_strain_type_tag, $desc_4);

    my $desc_7 = "Non-strain gene-tree species set '$species_set_name' has no associated 'prefer_for_genomes' MLSS tags";
    my %prefer_for_genome_tag_set = map { $_ => 1 } values %{$prefer_for_genome_map{$species_set_id}};
    my @prefer_for_genome_tags = keys %prefer_for_genome_tag_set;
    my $lacks_prefer_for_genome_tag = scalar(@prefer_for_genome_tags) == 1 && $prefer_for_genome_tags[0] eq '';
    ok($lacks_prefer_for_genome_tag, $desc_7)
      || diag explain [sort @prefer_for_genome_tags];
  }
}

1;
