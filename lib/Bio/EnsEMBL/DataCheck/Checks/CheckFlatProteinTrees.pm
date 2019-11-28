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

package Bio::EnsEMBL::DataCheck::Checks::CheckFlatProteinTrees;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckFlatProteinTrees',
  DESCRIPTION    => 'Check protein tree integrity ensuring number of leaves with parent node at root < 3',
  GROUPS         => ['compara', 'compara_protein_trees'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['gene_tree_node', 'gene_tree_root']
};

sub tests {
  my ($self) = @_;
  my $dba = $self->dba;
  my $helper = $dba->dbc->sql_helper;

  # Count and collect nodes with root_id != 0 and is not a seq_member
  my $internal_node_sql = qq/
    SELECT gtn.root_id, COUNT(*) AS internal_nodes 
      FROM gene_tree_node gtn 
    WHERE gtn.seq_member_id IS NULL 
      AND gtn.node_id <> gtn.root_id 
      AND gtn.root_id <> 0 
    GROUP BY gtn.root_id
  /;
  my $internal_node = $helper->execute_into_hash(  
   -SQL => $internal_node_sql
  );

  # Count and collect seq_members where root_id != 0, parent_id==root_id and count>1
  my $flat_member_sql = qq/
    SELECT gtn.root_id, COUNT(*) AS root_members 
      FROM gene_tree_node gtn 
    WHERE gtn.seq_member_id IS NOT NULL 
      AND gtn.parent_id = gtn.root_id 
      AND gtn.root_id <> 2 
    GROUP BY gtn.root_id 
    HAVING root_members > 1
  /;
  my $flat_members = $helper->execute(  
   -SQL => $flat_member_sql,
   -USE_HASHREFS => 1
  );

  # Count and collect all node memmbers where root_id != 0
  my $all_members_sql = qq/
    SELECT root_id, COUNT(DISTINCT root_id) AS root_count 
      FROM gene_tree_node 
    WHERE root_id <> 0 
    GROUP BY root_id
  /;
  my $all_members = $helper->execute_into_hash(  
   -SQL => $all_members_sql
  );

  # Collect all non-rooted trees
  my $nonrooted_trees_sql = qq/
    SELECT root_id, 1
      FROM gene_tree_root 
    WHERE tree_type = 'tree' 
      AND clusterset_id LIKE '%_it_%' 
      AND clusterset_id NOT LIKE 'pg_it_%'
  /;
  my $nonrooted_trees = $helper->execute_into_hash( 
    -SQL => $nonrooted_trees_sql
  );

  my @flat_trees;
  my @flat_trees_w_structure;

  foreach my $flat_member ( @$flat_members ) {
    my $node_id = $flat_member->{root_id};
    my $count = $flat_member->{root_members};
    # Check if $node_id is present in $nonrooted_trees
    if (exists $internal_node->{$node_id} ) {
     # if ( $internal_node->{$node_id} > 0 ) {
        if ( !exists $nonrooted_trees->{$node_id} ) {
          push @flat_trees_w_structure, $node_id;
        }
      #}
    } # Check that root has no more than 2 members
    elsif ( defined $count ) {
      if ( ($count > 2) && ($count == $all_members->{$node_id} )) {
        push @flat_trees, $node_id;
      }
    }
  }

  my $desc_1 = "There is less than two seq_members with parent as root and a well formed internal tree structure";
  my $desc_2 = "There are flat trees with more than 2 nodes to a root";
  ok( scalar(@flat_trees_w_structure) == 0, $desc_1 );
  ok( scalar(@flat_trees) == 0, $desc_2 );
  
}

1;

