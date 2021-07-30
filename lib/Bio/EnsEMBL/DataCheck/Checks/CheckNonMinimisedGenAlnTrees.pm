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

package Bio::EnsEMBL::DataCheck::Checks::CheckNonMinimisedGenAlnTrees;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'CheckNonMinimisedGenAlnTrees',
  DESCRIPTION => 'Check that all genomic align trees are binary, with the exception of unrooted EPO-extended trees which may have 3 sequences',
  GROUPS      => ['compara', 'compara_genome_alignments'],
  DB_TYPES    => ['compara'],
  TABLES      => ['genomic_align_tree', 'method_link_species_set']
};

sub tests {
  my ($self) = @_;

  my $desc_1 = "All genomic_align_tree trees are correct";
  my $sql_1 = q/
    SELECT * 
    FROM ( 
      SELECT 
        t1.root_id,
        COUNT(t1.parent_id) AS parents,
        SUM(t1.children = 3) AS threeleaf,
        SUM(t1.children > 2) AS non_bin,
        CASE t2.node_id WHEN NULL THEN 0 ELSE 1 END AS epo_ext
      FROM (
        SELECT root_id, parent_id, COUNT(node_id) AS children 
        FROM genomic_align_tree 
        WHERE parent_id IS NOT NULL 
        GROUP BY root_id, parent_id
      ) t1 
      LEFT JOIN (
        SELECT node_id FROM genomic_align_tree t
        JOIN method_link_species_set m 
        ON m.method_link_species_set_id * POWER(10, 10) <= t.node_id 
        AND t.node_id < (m.method_link_species_set_id + 1) * POWER(10, 10) 
        WHERE t.node_id=t.root_id AND m.method_link_id=14
      ) t2
      ON t1.root_id = t2.node_id
      GROUP BY t1.root_id 
      HAVING non_bin > 0
    ) t3 
    WHERE NOT (
      t3.epo_ext = 1 
      AND t3.parents = 1 
      AND t3.threeleaf = 1 
      AND t3.threeleaf = t3.non_bin
    );
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);
}

1;

