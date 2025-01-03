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

package Bio::EnsEMBL::DataCheck::Checks::CheckIDRangeMLSS;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw( is_compara_ehive_db );

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckIDRangeMLSS',
  DESCRIPTION    => 'All relevant IDs are within the offset range for their MLSS ID',
  GROUPS         => ['compara', 'compara_pairwise_alignments', 'compara_genome_alignments'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['compara'],
  TABLES         => ['genomic_align', 'genomic_align_block', 'genomic_align_tree', 'constrained_element', 'conservation_score', 'dnafrag']
};


sub skip_tests {
  my ($self) = @_;
  if (is_compara_ehive_db($self->dba) == 1) {
    return( 1, "This check is not intended for pipeline databases" );
  }
}


sub tests {
  my ($self) = @_;

  my $desc_1 = "genomic_align.genomic_align_id all within correct MLSS range";
  my $sql_1 = q/
    SELECT genomic_align_id, method_link_species_set_id
    FROM genomic_align
    WHERE genomic_align_id < (method_link_species_set_id * 10000000000) 
      OR genomic_align_id > ((method_link_species_set_id + 1) * 10000000000)
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);


  my $desc_2 = "genomic_align.genomic_align_block_id all within correct MLSS range";
  my $sql_2 = q/
    SELECT genomic_align_block_id, method_link_species_set_id
    FROM genomic_align
    WHERE genomic_align_block_id < (method_link_species_set_id * 10000000000) 
      OR genomic_align_block_id > ((method_link_species_set_id + 1) * 10000000000)
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2);


  my $desc_3 = "genomic_align_block.genomic_align_block_id all within correct MLSS range";
  my $sql_3 = q/
    SELECT genomic_align_block_id, method_link_species_set_id
    FROM genomic_align_block 
    WHERE genomic_align_block_id < (method_link_species_set_id * 10000000000) 
      OR genomic_align_block_id > ((method_link_species_set_id + 1) * 10000000000)
  /;
  is_rows_zero($self->dba, $sql_3, $desc_3);


  my $desc_4 = "genomic_align_block.group_id all within correct MLSS range";
  my $sql_4 = q/
    SELECT group_id, method_link_species_set_id
    FROM genomic_align_block 
    WHERE group_id < (method_link_species_set_id * 10000000000) 
      OR group_id > ((method_link_species_set_id + 1) * 10000000000)
  /;
  is_rows_zero($self->dba, $sql_4, $desc_4);


  my $desc_5 = "genomic_align_tree.node_id all within correct MLSS range";
  my $sql_5 = q/
    SELECT DISTINCT(t.node_id), g.method_link_species_set_id 
    FROM genomic_align_tree t 
    JOIN genomic_align g 
      ON g.node_id=t.node_id
    WHERE t.node_id < (g.method_link_species_set_id * 10000000000) 
      OR t.node_id > ((g.method_link_species_set_id + 1) * 10000000000)
  /;
  is_rows_zero($self->dba, $sql_5, $desc_5);


  my $desc_6 = "constrained_element.constrained_element_id all within correct MLSS range";
  my $sql_6 = q/
    SELECT constrained_element_id, method_link_species_set_id
    FROM constrained_element 
    WHERE constrained_element_id < (method_link_species_set_id * 10000000000) 
      OR constrained_element_id > ((method_link_species_set_id + 1) * 10000000000)
  /;
  is_rows_zero($self->dba, $sql_6, $desc_6);


  my $desc_7 = "dnafrag.dnafrag_id for ancestral frags all within correct MLSS range";
  my $sql_7 = q/
    SELECT d.dnafrag_id, g.method_link_species_set_id 
    FROM dnafrag d 
    JOIN genomic_align g 
      ON g.dnafrag_id=d.dnafrag_id
    WHERE d.name LIKE 'Ancestor%'
      AND (
        d.dnafrag_id < (g.method_link_species_set_id * 10000000000) 
        OR d.dnafrag_id > ((g.method_link_species_set_id + 1) * 10000000000)
      )
  /;
  is_rows_zero($self->dba, $sql_7, $desc_7);


  my $desc_8 = "conservation_score.genomic_align_block_id all within correct MLSS range";
  my $sql_8 = q/
    SELECT cs.genomic_align_block_id, g.method_link_species_set_id
    FROM conservation_score cs 
    JOIN genomic_align_block g 
      ON g.genomic_align_block_id=cs.genomic_align_block_id
    WHERE g.genomic_align_block_id < (g.method_link_species_set_id * 10000000000) 
      OR g.genomic_align_block_id > ((g.method_link_species_set_id + 1) * 10000000000)
  /;
  is_rows_zero($self->dba, $sql_8, $desc_8);
}

1;
