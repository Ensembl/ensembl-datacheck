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

package Bio::EnsEMBL::DataCheck::Checks::ForeignKeysCompara;

use warnings;
use strict;

use Moose;
use Path::Tiny;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/repo_location is_compara_ehive_db/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ForeignKeysCompara',
  DESCRIPTION => 'Foreign key relationships are not violated',
  GROUPS      => ['compara', 'compara_gene_trees', 'compara_genome_alignments', 'compara_master', 'compara_syntenies'],
  DB_TYPES    => ['compara'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  my $table_sql_file = $self->table_sql_file();

  my @failed_to_parse;

  my $table1;
  foreach my $line ( path($table_sql_file)->lines ) {
    if ($line =~ /CREATE TABLE `?(\w+)`?/) {
      $table1 = $1;
    } elsif (defined $table1) {
      next if $line =~ /^\-\-/;
      next unless $line =~ /FOREIGN KEY/;

      my ($col1, $table2, $col2) = $line =~
        /\s*FOREIGN\s+KEY\s+\((\S+)\)\s+REFERENCES\s+(\S+)\s*\((\S+)\)/i;
      if (defined $col1 && defined $table2 && defined $col2) {
        # Because the master database may have old genomes linked to deprecated taxon_ids
        if ($self->dba->dbc->dbname =~ /master/) {
          next if "$table1 $col1 $table2 $col2" eq 'genome_db taxon_id ncbi_taxa_node taxon_id';
        }
        fk($self->dba, $table1, $col1, $table2, $col2);
      } else {
        push @failed_to_parse, $line;
      }
    }
  }

  my $desc_parsed = "Parsed all foreign key relationships from file";
  is(scalar(@failed_to_parse), 0, $desc_parsed) ||
    diag explain @failed_to_parse;

  $self->compara_fk();
}

sub table_sql_file {
  my ($self) = @_;

  # Don't need checking here, the DB_TYPES ensure we won't get
  # a $dba from a group that we can't handle, and the repo_location
  # method will die if the repo path isn't visible to Perl.
  my $repo_location  = repo_location($self->dba->group);
  my $table_sql_file = "$repo_location/sql/table.sql";

  if (! -e $table_sql_file) {
    die "Table file does not exist: $table_sql_file";
  }

  return $table_sql_file;
}

sub compara_fk {
  my ($self) = @_;
  # Check for incorrect foreign key relationships that are not defined
  # in the "table.sql" file.

  # Standard FK constraints that are missing from "table.sql".
  fk($self->dba, 'species_tree_node', 'parent_id', 'species_tree_node', 'node_id');
  fk($self->dba, 'species_tree_node', 'root_id', 'species_tree_node', 'node_id');
  fk($self->dba, 'species_tree_node', 'root_id', 'species_tree_root');

  fk($self->dba, 'genomic_align_tree', 'parent_id', 'genomic_align_tree', 'node_id');
  fk($self->dba, 'genomic_align_tree', 'root_id', 'genomic_align_tree', 'node_id');
  fk($self->dba, 'genomic_align_tree', 'left_node_id', 'genomic_align_tree', 'node_id');
  fk($self->dba, 'genomic_align_tree', 'right_node_id', 'genomic_align_tree', 'node_id');

  # Cases in which we want to check for the reverse direction of the FK constraint
  fk($self->dba, 'family',              'family_id',              'family_member');
  fk($self->dba, 'homology',            'homology_id',            'homology_member');
  fk($self->dba, 'synteny_region',      'synteny_region_id',      'dnafrag_region');
  fk($self->dba, 'genomic_align_block', 'genomic_align_block_id', 'genomic_align');

  # Reverse direction FK constraint, but not applicable to compara_master or pipeline dbs
  if ($self->dba->dbc->dbname !~ /_master/ && is_compara_ehive_db($self->dba) != 1) {
    fk($self->dba, 'method_link', 'method_link_id', 'method_link_species_set');
    fk($self->dba, 'species_set', 'species_set_id', 'method_link_species_set');
    fk($self->dba, 'genome_db',   'genome_db_id',   'species_set',             undef, 'name != "ancestral_sequences"' );
  }

  # Cases in which we need to restrict to a subset of rows, using a constraint
  my $genomic_align_constraint = q/
    method_link_id IN (
      SELECT method_link_id FROM method_link
      WHERE
        method_link_id < 100 AND
        class LIKE "GenomicAlign%" AND
        type NOT LIKE "CACTUS_HAL%"
    )
  /;
  fk($self->dba, 'genomic_align',       'method_link_species_set_id', 'method_link_species_set', 'method_link_species_set_id', $genomic_align_constraint);
  fk($self->dba, 'genomic_align_block', 'method_link_species_set_id', 'method_link_species_set', 'method_link_species_set_id', $genomic_align_constraint);

  my $constrained_element_constraint = q/
    method_link_id IN (
      SELECT method_link_id FROM method_link
      WHERE
        method_link_id < 100 AND
        class LIKE "ConstrainedElement.%"
    )
  /;
  fk($self->dba, 'constrained_element', 'method_link_species_set_id', 'method_link_species_set', 'method_link_species_set_id', $constrained_element_constraint);

  my $synteny_region_constraint = q/
    method_link_id IN (
      SELECT method_link_id FROM method_link
      WHERE
        method_link_id > 100 AND
        method_link_id < 200
    )
  /;
  fk($self->dba, 'synteny_region', 'method_link_species_set_id', 'method_link_species_set', 'method_link_species_set_id', $synteny_region_constraint);

  my $homology_constraint = q/
    method_link_id IN (
      SELECT method_link_id FROM method_link
      WHERE
        method_link_id > 200 AND
        method_link_id < 300
    )
  /;
  fk($self->dba, 'homology', 'method_link_species_set_id', 'method_link_species_set', 'method_link_species_set_id', $homology_constraint);

  my $family_constraint = q/
    method_link_id IN (
      SELECT method_link_id FROM method_link
      WHERE
        method_link_id > 300 AND
        method_link_id < 400
    )
  /;
  fk($self->dba, 'family', 'method_link_species_set_id', 'method_link_species_set', 'method_link_species_set_id', $family_constraint);

  my $tree_constraint = q/
    method_link_id IN (
      SELECT method_link_id FROM method_link
      WHERE
        method_link_id > 400 AND
        method_link_id < 500
    )
  /;
  fk($self->dba, 'gene_tree_root',    'method_link_species_set_id', 'method_link_species_set', 'method_link_species_set_id', $tree_constraint);
  fk($self->dba, 'species_tree_root', 'method_link_species_set_id', 'method_link_species_set', 'method_link_species_set_id', $tree_constraint);

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
