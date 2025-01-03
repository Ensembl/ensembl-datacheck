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

package Bio::EnsEMBL::DataCheck::Checks::CheckComparaStableIDs;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckComparaStableIDs',
  DESCRIPTION    => 'gene trees in gene_tree_root and family all have stable_ids generated',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_gene_tree_pipelines'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['family', 'gene_tree_root']
};

sub tests {
  my ($self) = @_;
  my $desc_1 = "There are no NULL stable_ids in family";
  my $sql_1 = q/
    SELECT * 
      FROM family 
    WHERE stable_id IS NULL
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);
  
  my $desc_2 = "There are no NULL stable_ids for gene trees in gene_tree_root";
  my $sql_2 = q/
    SELECT * FROM gene_tree_root 
      WHERE member_type = 'protein' 
        AND tree_type = 'tree' 
        AND clusterset_id='default' 
        AND stable_id IS NULL
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2);

  my $desc_3 = "All gene-tree stable_ids follow the standard format";
  my $sql_3 = qq/
    SELECT stable_id FROM gene_tree_root
      WHERE member_type = 'protein'
        AND tree_type = 'tree'
        AND clusterset_id =  "default"
        AND stable_id IS NOT NULL
  /;

  my $stable_ids = $self->dba->dbc->db_handle->selectcol_arrayref($sql_3);

  my %stable_id_prefixes;
  my $num_non_standard_stable_ids = 0;
  foreach my $stable_id (@{$stable_ids}) {
    if ($stable_id =~ /^([A-Za-z]+)GT[0-9]{14}$/) {
      $stable_id_prefixes{$1} = 1;
    } else {
      $num_non_standard_stable_ids += 1;
    }
  }
  is($num_non_standard_stable_ids, 0, $desc_3);

  my $num_stable_id_prefixes = scalar(keys %stable_id_prefixes);
  SKIP: {
    skip "No standard-format stable_ids found in default gene trees" unless $num_stable_id_prefixes > 0;

    my $desc_4 = "There is a single consistent prefix for all standard-format gene tree stable_ids";
    is($num_stable_id_prefixes, 1, $desc_4);
  }
}

1;

