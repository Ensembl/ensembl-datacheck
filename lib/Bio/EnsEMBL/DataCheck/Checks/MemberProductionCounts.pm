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

package Bio::EnsEMBL::DataCheck::Checks::MemberProductionCounts;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::Utils::SqlHelper;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'MemberProductionCounts',
  DESCRIPTION    => 'Checks that the gene_member counts are appropriately populated',
  GROUPS         => ['compara', 'compara_gene_trees'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['CAFE_gene_family', 'family', 'gene_member', 'gene_member_hom_stats', 'gene_tree_root', 'genome_db']
};

sub skip_tests {
    my ($self) = @_;
    my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
    my @methods = qw( PROTEIN_TREES NC_TREES );
    my $db_name = $self->dba->dbc->dbname;

    my @mlsses;
    foreach my $method ( @methods ) {
      my $mlss = $mlss_adap->fetch_all_by_method_link_type($method);
      push @mlsses, @$mlss;
    }

    if ( scalar(@mlsses) == 0 ) {
      return( 1, "There are no multiple alignments in $db_name" );
    }
}

sub tests {
  my ($self) = @_;
  my $dba = $self->dba;
  my $dbc = $dba->dbc;
  my $helper = $dbc->sql_helper;
  my $gdb_adap = $dba->get_GenomeDBAdaptor;

  my $division = $dba->get_division();

  my $sql_sums = qq/
    SELECT SUM(families) AS sum_families, SUM(gene_trees) AS sum_gene_trees, SUM(gene_gain_loss_trees) AS sum_gene_gain_loss_trees, SUM(orthologues) AS sum_orthologues, SUM(paralogues) AS sum_paralogues, SUM(homoeologues) AS sum_homoeologues 
      FROM gene_member_hom_stats 
    WHERE collection = ?
  /;

  my $constraint = "tree_type = 'tree' AND ref_root_id IS NULL";
  my $sqlCollections = qq/
     SELECT DISTINCT clusterset_id 
       FROM gene_tree_root 
     WHERE $constraint
   /;

  my $collections = $helper->execute_simple( -SQL => $sqlCollections );

  my $sqlFamilies = q/
    SELECT COUNT(*) 
      FROM family
  /; # To be tested only with default
  my $family_count = $helper->execute_single_result( -SQL => $sqlFamilies );

  my $sqlPolyploids = q/
    SELECT COUNT(*) 
      FROM genome_db 
    WHERE genome_component IS NOT NULL
  /; # Assumes that the polyploid genomes are found in all the collections
  my $polyploid_count = $helper->execute_single_result( -SQL => $sqlPolyploids );

  my $sqlGeneTrees = qq/
    SELECT COUNT(*) 
      FROM gene_tree_root 
    WHERE clusterset_id = ?
  /;

  my $sqlCAFETrees = qq/
    SELECT COUNT(*) 
      FROM gene_tree_root 
        JOIN CAFE_gene_family 
          ON gene_tree_root.root_id = gene_tree_root_id 
    WHERE clusterset_id = ?
  /;

  my @columns = qw(families gene_trees gene_gain_loss_trees orthologues paralogues homoeologues);

  foreach my $collection ( @$collections ) {

    my $sums = $helper->execute( -SQL => $sql_sums, -USE_HASHREFS => 1, PARAMS => [$collection] );

    my $genetree_count = $helper->execute_single_result( -SQL => $sqlGeneTrees,  PARAMS => [$collection] );
    my $cafetrees_count = $helper->execute_single_result( -SQL => $sqlCAFETrees, PARAMS => [$collection] );
    
    my @counts = ($family_count, $genetree_count, $cafetrees_count, $genetree_count, $genetree_count, $polyploid_count);

    #Test for families commented out for duration of compara production freeze, this may return in the future

    # if ( $division =~ /vertebrates/ && $collection =~ /default/ ) {
    #   my $desc_5 = "The sum of entries for families in gene_member_hom_stats > 0 for the $collection collection";
    #   cmp_ok( $sums->[0]->{sum_families}, ">", 0, $desc_5 );
    #   my $desc_6 = "There are entries in the family table";
    #   cmp_ok( $counts[0], ">", 0, $desc_6 );
    #   my $desc_7 = "Found expected entries in gene_member_hom_stats with families > 0 for the $collection collection";
    #   my $desc_8 = "There were no unexpected entries in gene_member_hom_stats with families > 0 for the $collection collection";
    #   is( $sums->[0]->{sum_families} > 0, $counts[0] > 0, $desc_7 );
    # }
    if ( $division =~ /vertebrates/ || $collection =~ /default/ ) {
      my $desc_5 = "The sum of entries for gene_trees in gene_member_hom_stats > 0 for the $collection collection";
      cmp_ok( $sums->[0]->{sum_gene_trees}, ">", 0, $desc_5 );
      my $desc_6 = "There are entries in the gene_tree table";
      cmp_ok( $counts[1], ">", 0, $desc_6 );
    }

    foreach ( my $i = 1; $i < @columns; $i++ ) {
      my $col_name = "sum_$columns[$i]";
      my $desc_7 = "Found expected entries in gene_member_hom_stats with $columns[$i] > 0 for the $collection collection";
      my $desc_8 = "There were no unexpected entries in gene_member_hom_stats with $columns[$i] > 0 for the $collection collection";
      next if ( $collection !~ /default/ && $columns[$i] eq "families" );
      is( $sums->[0]->{$col_name} > 0, $counts[$i] > 0, $desc_7 );
    }

    my $desc_9 = "All homologs have gene_trees in the $collection collection";
    my $sqlBrokenHomologyCounts  = qq/
      SELECT COUNT(*) 
        FROM gene_member_hom_stats 
      WHERE gene_trees = 0 AND (orthologues > 0 OR paralogues > 0 OR homoeologues > 0) 
        AND collection = "$collection"
    /;
    is_rows_zero( $dbc, $sqlBrokenHomologyCounts, $desc_9 );

    my $desc_10 = "All gene_gain_loss_trees have gene_trees in the $collection collection";
    my $sqlBrokenGainLossCounts = qq/
      SELECT COUNT(*) 
        FROM gene_member_hom_stats 
      WHERE gene_trees = 0 
        AND gene_gain_loss_trees > 0 
        AND collection = "$collection"
    /;
    is_rows_zero( $dbc, $sqlBrokenGainLossCounts, $desc_10 );

    my $desc_11 = "All gene_trees>1 have an actual gene-tree for the $collection collection";
    my $sqlPopulateGMHS = qq/
      SELECT COUNT(*) 
        FROM gene_member_hom_stats 
          JOIN gene_member 
            USING (gene_member_id) 
          LEFT JOIN gene_tree_node 
            ON canonical_member_id = seq_member_id 
      WHERE node_id IS NULL 
        AND gene_trees > 0 
        AND collection = "$collection"
    /;
    is_rows_zero( $dbc, $sqlPopulateGMHS, $desc_11 );

    my $desc_12 = "All gene_trees=0 have no gene-tree for the $collection collection";
    my $sqlPopulatewithGTR = qq/
      SELECT COUNT(*) 
        FROM gene_member_hom_stats 
          JOIN gene_member 
            USING (gene_member_id) 
          JOIN gene_tree_node
            ON canonical_member_id = seq_member_id
          JOIN gene_tree_root USING (root_id)
      WHERE gene_trees = 0 
        AND collection = clusterset_id 
        AND collection = "$collection"
    /;
    is_rows_zero( $dbc, $sqlPopulatewithGTR, $desc_12 );

    my $sqlGenomeDBs = qq/
      SELECT DISTINCT genome_db_id 
        FROM gene_tree_root 
          JOIN method_link_species_set 
            USING (method_link_species_set_id) 
          JOIN species_set 
            USING (species_set_id) 
      WHERE clusterset_id = "$collection"
    /;

    my $genome_db_ids = $helper->execute_simple( -SQL => $sqlGenomeDBs );

    foreach my $genome_db_id ( @$genome_db_ids ) {
      my $gdb = $gdb_adap->fetch_by_dbID($genome_db_id);
      next if $gdb->genome_component;
      my $desc_13 = "There is data for genome_db_id $genome_db_id in gene_member_hom_stats for the $collection collection";
      my $sqlGDBCount = qq/
        SELECT COUNT(*) 
          FROM gene_member_hom_stats 
            JOIN gene_member 
              USING (gene_member_id) 
        WHERE collection = "$collection" AND genome_db_id = $genome_db_id
      /;

      is_rows_nonzero( $dbc, $sqlGDBCount, $desc_13 );
    }
  }
}

1;
