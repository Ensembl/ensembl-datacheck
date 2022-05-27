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
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_gene_tree_pipelines'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['gene_tree_node', 'gene_tree_root']
};

sub tests {
  my ($self) = @_;
  my $dba = $self->dba;
  my $helper = $dba->dbc->sql_helper;

  # Count and collect nodes that are not a seq_member
  my $internal_node_sql = qq/
    SELECT gtn.root_id, COUNT(*) AS internal_nodes 
      FROM gene_tree_node gtn 
    WHERE gtn.seq_member_id IS NULL 
      AND gtn.node_id <> gtn.root_id 
    GROUP BY gtn.root_id
  /;
  my $internal_node = $helper->execute_into_hash(
   -SQL => $internal_node_sql
  );

  # Count and collect seq_members where parent_id is a root_id and count>1
  my $flat_member_sql = qq/
    SELECT gtn.root_id, COUNT(*) AS root_members 
      FROM gene_tree_node gtn 
    WHERE gtn.seq_member_id IS NOT NULL 
      AND gtn.parent_id = gtn.root_id 
    GROUP BY gtn.root_id 
    HAVING root_members > 1
  /;
  my $flat_members = $helper->execute_into_hash(
   -SQL => $flat_member_sql,
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

  foreach my $root_id ( keys %$flat_members ) {
    my $count = $flat_members->{$root_id};
    my $max_allowed_root_members = exists $nonrooted_trees->{$root_id} ? 3 : 2;
    if ($count > $max_allowed_root_members) {
      # FAIL: too many members attached to the root node (regardless of the internal structure)
      if (exists $internal_node->{$root_id} ) {
        push @flat_trees_w_structure, $root_id;
      }
      else {
        push @flat_trees, $root_id;
      }
    }
    elsif ($count == $max_allowed_root_members) {
      if (exists $internal_node->{$root_id} ) {
        # FAIL: too many nodes attached to the root
        push @flat_trees_w_structure, $root_id;
      }
    }
  }

  my $desc_1 = "There is less than two seq_members with parent as root and a well formed internal tree structure";
  my $desc_2 = "There are flat trees with more than 2 nodes to a root";
  is( scalar(@flat_trees), 0, $desc_2 );
  is( scalar(@flat_trees_w_structure), 0, $desc_1 );

}

1;

