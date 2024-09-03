=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::SupertreeTopology;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'SupertreeTopology',
  DESCRIPTION    => 'Check that the topology of each supertree is as expected',
  GROUPS         => ['compara', 'compara_gene_tree_pipelines', 'compara_gene_trees'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['gene_tree_node', 'gene_tree_root']
};


sub tests {
  my ($self) = @_;

  my $dbc = $self->dba->dbc;
  my $helper = $dbc->sql_helper;

  my @supertree_constraints = (
    "Every node in supertree must have at least one child",
    "Root of supertree must have at least two children",
    "Internal nodes of supertree must have two children",
    "Supertree cannot have invalid subtree links",
    "Supertree must have at least two subtrees",
  );

  my $supertree_sql = qq/
    SELECT
      root_id
    FROM
      gene_tree_root
    WHERE
      tree_type = 'supertree'
  /;

  my $supertree_root_ids = $helper->execute_simple( -SQL => $supertree_sql );

  SKIP: {
skip sprintf("There are no supertrees in %s", $dbc->dbname) if scalar(@{$supertree_root_ids}) == 0;

    my $supertree_node_sql = q/
      SELECT
        gtn1.node_id AS parent_node_id,
        gtn1.root_id AS parent_root_id,
        gtn2.node_id AS child_node_id,
        gtn2.root_id AS child_root_id
      FROM
        gene_tree_node gtn1
      LEFT JOIN
        gene_tree_node gtn2 ON gtn2.parent_id = gtn1.node_id
      WHERE
        gtn1.root_id = ?
    /;

    my %failed_constraints = map { $_ => [] } @supertree_constraints;
    foreach my $supertree_root_id (@$supertree_root_ids) {

      my $results = $helper->execute(
        -SQL => $supertree_node_sql,
        -PARAMS => [$supertree_root_id],
      );

      my %parent_to_child_ids;
      my %internal_node_id_set;
      my %supertree_bud_id_set;
      my %valid_subtree_root_set;
      my $num_childless_nodes = 0;
      foreach my $result (@{$results}) {
        my ($parent_node_id, $parent_root_id, $child_node_id, $child_root_id) = @{$result};

        unless (defined $child_node_id) {
          $num_childless_nodes += 1;
          next;
        }

        push(@{$parent_to_child_ids{$parent_node_id}}, $child_node_id);

        if ($parent_node_id != $parent_root_id) {
          if ($child_root_id == $parent_root_id) {
            $internal_node_id_set{$parent_node_id} = 1;
          } else {
            $supertree_bud_id_set{$parent_node_id} = 1;
            if ($child_node_id == $child_root_id) {
              $valid_subtree_root_set{$child_node_id} = 1;
            }
          }
        }
      }

      if ($num_childless_nodes > 0) {
        push(@{$failed_constraints{"Every node in supertree must have at least one child"}}, $supertree_root_id);
      }

      my $num_root_children = exists $parent_to_child_ids{$supertree_root_id}
                            ? scalar(@{$parent_to_child_ids{$supertree_root_id}})
                            : 0
                            ;
      if ($num_root_children < 2) {
        push(@{$failed_constraints{"Root of supertree must have at least two children"}}, $supertree_root_id);
      }

      my $num_non_binary_internal_nodes = 0;
      foreach my $internal_node_id (keys %internal_node_id_set) {
        my $num_children = scalar(@{$parent_to_child_ids{$internal_node_id}});
        if ($num_children != 2) {
          push(@{$failed_constraints{"Internal nodes of supertree must have two children"}}, $supertree_root_id);
          last;
        }
      }

      my $num_valid_subtree_links = 0;
      my $num_invalid_subtree_links = 0;
      foreach my $supertree_bud_id (keys %supertree_bud_id_set) {
        my @bud_child_ids = @{$parent_to_child_ids{$supertree_bud_id}};
        if (scalar(@bud_child_ids) == 1 && exists $valid_subtree_root_set{$bud_child_ids[0]}) {
          $num_valid_subtree_links += 1;
        } else {
          $num_invalid_subtree_links += 1;
        }
      }

      if ($num_invalid_subtree_links > 0) {
        push(@{$failed_constraints{"Supertree cannot have invalid subtree links"}}, $supertree_root_id);
      }

      if ($num_valid_subtree_links < 2) {
        push(@{$failed_constraints{ "Supertree must have at least two subtrees"}}, $supertree_root_id);
      }
    }

    foreach my $constraint (@supertree_constraints) {
      my @flagged_supertrees = @{$failed_constraints{$constraint}};
      is(scalar(@flagged_supertrees), 0, $constraint)
        || diag explain [sort { $a <=> $b } @flagged_supertrees];
    }
  }
}


1;
