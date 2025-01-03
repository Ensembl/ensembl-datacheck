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

package Bio::EnsEMBL::DataCheck::Checks::MemberXrefAccessTime;

use warnings;
use strict;

use Moose;
use Test::More;

use Bio::EnsEMBL::Compara::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Compara::DBSQL::XrefAssociationAdaptor;
use Bio::EnsEMBL::Hive::Utils qw/timeout/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';


use constant {
  NAME           => 'MemberXrefAccessTime',
  DESCRIPTION    => 'Compara member xref data can be accessed in a timely manner',
  GROUPS         => ['compara_annot_highlight'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  PER_DB         => 1,
  # The 'TABLES' array is left empty in case an issue arises with Member Xref access of unchanged data.
  # Relevant tables are: external_db, gene_member, gene_tree_node, gene_tree_root, member_xref, seq_member
  TABLES         => [],
};


sub skip_tests {
  my ($self) = @_;

  if ( $self->dba->get_division eq 'vertebrates' ) {
    return( 1, "The member_xref table is not populated for vertebrates" );
  }
}

sub tests {
  my ($self) = @_;

  my $helper = $self->dba->dbc->sql_helper;


  my $external_db_query = q/
    SELECT
      db_name
    FROM
      external_db
    LIMIT 1;
  /;

  my $external_db_name = $helper->execute_single_result(-SQL => $external_db_query);


  my $avg_tree_size_query = q/
      SELECT
          ROUND(AVG(gene_count))
      FROM
          gene_tree_root
      JOIN
          gene_tree_root_attr USING(root_id)
      WHERE
          tree_type = 'tree'
      AND
          clusterset_id = 'default'
      AND
          gene_count  > 4;
  /;

  my $avg_tree_size = $helper->execute_single_result(-SQL => $avg_tree_size_query);


  my $test_tree_query = q/
      SELECT
          root_id
      FROM
          gene_tree_root
      JOIN
          gene_tree_root_attr
      USING
          (root_id)
      WHERE
          tree_type = 'tree'
      AND
          clusterset_id = 'default'
      AND
          gene_count >= ?
      ORDER BY
          gene_count;
  /;

  my $gene_tree_root_ids = $helper->execute_simple(-SQL => $test_tree_query, -PARAMS => [$avg_tree_size]);


  my $xref_assoc_dba = Bio::EnsEMBL::Compara::DBSQL::XrefAssociationAdaptor->new($self->dba);
  my $gene_tree_dba = $self->dba->get_GeneTreeAdaptor;

  my $member_xref_access_timeout = 60;

  my $timed_out_tree_stable_id;
  foreach my $root_id (@{$gene_tree_root_ids}) {
    my $tree = $gene_tree_dba->fetch_by_root_id($root_id);

    my $return_value = timeout( sub {
      my @xrefs = sort { $a cmp $b } @{$xref_assoc_dba->get_associated_xrefs_for_tree($tree , $external_db_name)};
      if (scalar(@xrefs) > 0) {
        my @xref_members = @{$xref_assoc_dba->get_members_for_xref($tree, $xrefs[0], $external_db_name)};
      }
    }, $member_xref_access_timeout);

    if ($return_value == -2) {
      $timed_out_tree_stable_id = $tree->stable_id;
    }
  }

  my $desc = "Member xref data can be accessed in a timely manner";
  is($timed_out_tree_stable_id, undef, $desc);
}

1;
