=head1 LICENSE

Copyright [2018-2021] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::ForeignKeysCompara;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/foreign_keys is_compara_ehive_db/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ForeignKeysCompara',
  DESCRIPTION => 'Foreign key relationships are not violated',
  GROUPS      => ['compara', 'compara_gene_trees', 'compara_genome_alignments', 'compara_master', 'compara_syntenies', 'compara_references', 'compara_homology_annotation'],
  DB_TYPES    => ['compara'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  my ($foreign_keys, $failed_to_parse) = foreign_keys($self->dba->group);

  foreach my $relationship (@$foreign_keys) {
    # Because the master database may have old genomes linked to deprecated taxon_ids
    if ($self->dba->dbc->dbname =~ /master/) {
      next if join(" ", @$relationship) eq 'genome_db taxon_id ncbi_taxa_node taxon_id';
    }
    if ($self->dba->dbc->dbname !~ /[ensembl_compara|protein_trees|ncrna_trees]/) {
      next if join(" ", @$relationship) =~ /homology_member.*[gene_member_id|seq_member_id]/;
      next if join(" ", @$relationship) =~ /peptide_align_feature.*[gene_member_id|seq_member_id]/;
    }
    fk($self->dba, @$relationship);
  }

  my $desc_parsed = "Parsed all foreign key relationships from file";
  is(scalar(@$failed_to_parse), 0, $desc_parsed) ||
    diag explain @$failed_to_parse;

  $self->compara_fk();
}

sub compara_fk {
  my ($self) = @_;
  # Check for incorrect foreign key relationships that are not defined
  # in the "table.sql" file.

  # Standard FK constraints that are missing from "table.sql".
  fk($self->dba, 'species_tree_node', 'root_id', 'species_tree_root');

  fk($self->dba, 'genomic_align_tree', 'root_id', 'genomic_align_tree', 'node_id');

  # Cases in which we want to check for the reverse direction of the FK constraint
  fk($self->dba, 'family',              'family_id',              'family_member');
  fk($self->dba, 'homology',            'homology_id',            'homology_member');
  fk($self->dba, 'synteny_region',      'synteny_region_id',      'dnafrag_region');
  fk($self->dba, 'genomic_align_block', 'genomic_align_block_id', 'genomic_align');

  # Reverse direction FK constraint, but not applicable to compara_master or pipeline dbs
  if ($self->dba->dbc->dbname !~ /[_master|_reference]/ && is_compara_ehive_db($self->dba) != 1) {
    fk($self->dba, 'method_link', 'method_link_id', 'method_link_species_set');
    fk($self->dba, 'species_set', 'species_set_id', 'method_link_species_set');
    fk($self->dba, 'genome_db',   'genome_db_id',   'species_set',             undef, 'name != "ancestral_sequences"' );
  }

  # Cases in which we need to restrict to a subset of rows, using a constraint

  my $hom_stats_constraint = q/
    tree_type = 'tree' AND 
    ref_root_id IS NULL
  /;
  fk($self->dba, "gene_member_hom_stats", "collection", "gene_tree_root", "clusterset_id", $hom_stats_constraint);

  my $mlss_tag_genome_constraint = q/
    tag LIKE '%reference_species'
  /;
  fk($self->dba, "method_link_species_set_tag", "value", "genome_db", "name", $mlss_tag_genome_constraint);

  my $mlss_tag_msa_constraint = q/
    tag = 'msa_mlss_id'
  /;
  fk($self->dba, "method_link_species_set_tag", "value", "method_link_species_set", "method_link_species_set_id", $mlss_tag_msa_constraint);

  
}

1;
