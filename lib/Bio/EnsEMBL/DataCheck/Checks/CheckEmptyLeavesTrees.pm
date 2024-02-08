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

package Bio::EnsEMBL::DataCheck::Checks::CheckEmptyLeavesTrees;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckEmptyLeavesTrees',
  DESCRIPTION    => 'Check that none of the gene tree leaves have children',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_gene_tree_pipelines'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['gene_tree_node']
};

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;
  
  my $sql = q/
    SELECT DISTINCT g1.root_id 
      FROM gene_tree_node g1 
        LEFT JOIN gene_tree_node g2 
          ON (g1.node_id=g2.parent_id) 
    WHERE g2.node_id IS NULL 
      AND (g1.right_index-g1.left_index) > 1
  /;
  
  
  my $desc = "None of the gene trees have leaves with children";
  is_rows_zero($dbc, $sql, $desc);
}

1;

