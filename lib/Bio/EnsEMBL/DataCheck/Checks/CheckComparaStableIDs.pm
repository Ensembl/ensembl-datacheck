=head1 LICENSE

Copyright [2018-2021] EMBL-European Bioinformatics Institute

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
  GROUPS         => ['compara', 'compara_gene_trees'],
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
  
}

1;

