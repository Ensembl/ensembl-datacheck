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

package Bio::EnsEMBL::DataCheck::Checks::CheckHomology;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckHomology',
  DESCRIPTION    => 'Check homology_id are all one-to-many for homology_members',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_homology_annotation', 'compara_blastocyst', 'compara_gene_tree_pipelines'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['homology', 'homology_member']
};

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;

  my $desc_1 = "Each homology_id is seen with more than one homology_member";
  is_one_to_many($dbc, "homology_member", "homology_id", $desc_1);
  ### Hoping for a better idea than this query (below)
  my $hideous_sql = q/
    SELECT
      hm1.gene_member_id gene_member_id1,
      hm2.gene_member_id gene_member_id2,
      COUNT(*) num,
      GROUP_CONCAT(h1.description
          ORDER BY h1.description) descs
    FROM
      homology h1
          CROSS JOIN
      homology_member hm1 USING (homology_id)
          CROSS JOIN
      homology_member hm2 USING (homology_id)
    WHERE
      hm1.gene_member_id < hm2.gene_member_id
    GROUP BY h1.gene_tree_root_id, hm1.gene_member_id, hm2.gene_member_id
    HAVING COUNT(*) > 1
  /;

  my $desc_2 = "There is no redundancy in homology";
  is_rows_zero($dbc, $hideous_sql, $desc_2);

}

1;

