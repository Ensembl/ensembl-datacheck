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

package Bio::EnsEMBL::DataCheck::Checks::CheckSpeciesTreeNodeAttr;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckSpeciesTreeNodeAttr',
  DESCRIPTION    => 'Check some entries in species_tree_node_attr are > 0',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_gene_tree_pipelines'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['species_tree_node_attr', 'species_tree_root']
};

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;
  my @tables = qw(species_tree_node_attr species_tree_root);
  my @columns = qw(root_nb_trees nb_genes);
  
  foreach my $table ( @tables ) {
    my $sql_1 = qq/
      SELECT COUNT(*)
        FROM $table
    /;
    my $desc_1 = "$table is populated";
    is_rows_nonzero($dbc, $sql_1, $desc_1);
  }
  
  foreach my $column ( @columns ) {
    my $sql_2 = qq/
      SELECT COUNT(*) 
        FROM species_tree_node_attr 
      WHERE $column > 0;
    /;
    my $desc_2 = "$column in species_tree_node_attr is sometimes > 0";
    is_rows_nonzero($dbc, $sql_2, $desc_2);
  }
  
}

1;

