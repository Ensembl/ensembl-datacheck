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

package Bio::EnsEMBL::DataCheck::Checks::CheckTableSizes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/ array_diff /;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckTableSizes',
  DESCRIPTION    => 'Tables must be populated and not differ significantly in row numbers',
  GROUPS         => ['compara', 'compara_tables'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['compara'],
  TABLES         => ['CAFE_gene_family', 'CAFE_species_gene', 'conservation_score', 'constrained_element', 'dnafrag', 'dnafrag_region', 'exon_boundaries', 'external_db', 'family', 'family_member', 'gene_align', 'gene_align_member', 'gene_member', 'gene_member_hom_stats', 'gene_member_qc', 'gene_tree_node', 'gene_tree_node_attr', 'gene_tree_node_tag', 'gene_tree_object_store', 'gene_tree_root', 'gene_tree_root_attr', 'gene_tree_root_tag', 'genome_db', 'genomic_align', 'genomic_align_block', 'genomic_align_tree', 'hmm_annot', 'hmm_curated_annot', 'hmm_profile', 'homology', 'homology_member', 'mapping_session', 'member_xref', 'method_link', 'method_link_species_set', 'method_link_species_set_attr', 'method_link_species_set_tag', 'ncbi_taxa_name', 'ncbi_taxa_node', 'other_member_sequence', 'peptide_align_feature', 'seq_member', 'seq_member_projection', 'seq_member_projection_stable_id', 'sequence', 'species_set', 'species_set_header', 'species_set_tag', 'species_tree_node', 'species_tree_node_attr', 'species_tree_node_tag', 'species_tree_root', 'stable_id_history', 'synteny_region']
};

sub tests {
  my ($self) = @_;
  
  my $registry = $self->registry;
  
  my $curr_dba = $self->dba;
  my $curr_helper = $curr_dba->dbc->sql_helper;
  my $prev_dba = Bio::EnsEMBL::Compara::DBSQL::DBAdaptor->go_figure_compara_dba('compara_prev');
  my $prev_helper = $prev_dba->dbc->sql_helper;
  
  my $table_sql = "SHOW TABLES";
  my $curr_tables = $curr_helper->execute_simple( -SQL => $table_sql );
  my $prev_tables = $prev_helper->execute_simple( -SQL => $table_sql );
  my $curr_db_name = $curr_dba->dbc->dbname;
  my $prev_db_name = $prev_dba->dbc->dbname;
  
  my %prev_tables = ();
  foreach my $table ( @$prev_tables ) {
    $prev_tables{$table}++;
  }
  
  foreach my $table ( @$curr_tables ) {
    my $desc_1 = "The number of rows in $table for $curr_db_name has not increased by >10% from $prev_db_name";
    my $desc_2 = "The number of rows in $table for $curr_db_name has not decreased by >5% from $prev_db_name";
    my $desc_3 = "The number of rows in $table have not remained static between $curr_db_name and $prev_db_name";
    my $sql = qq/
      SELECT COUNT(*) FROM $table
    /;
      
    if ( exists($prev_tables{$table}) ) {
      row_totals( $prev_dba, $curr_dba, $sql, $sql, 0.9, $desc_1 );
      row_totals( $curr_dba, $prev_dba, $sql, $sql, 0.95, $desc_2 );
      
      my $prev_row_count = $prev_helper->execute_single_result( -SQL => $sql );

      cmp_rows( $curr_dba->dbc, $sql, '!=', $prev_row_count, $desc_3 );
        
  } else {
      my $desc_4 = "Table: $table is new in $curr_db_name";
      pass( $desc_4 );
    }
  }
  
  my $desc = "There are no tables missing in $curr_db_name that were present in $prev_db_name";
  cmp_ok( scalar(@$curr_tables), '=>', scalar(@$prev_tables), $desc );
  if ( scalar(@$curr_tables) != scalar(@$prev_tables) ) {
    diag explain array_diff( $curr_tables, $prev_tables, $curr_db_name, $prev_db_name );
  }
}

1;

