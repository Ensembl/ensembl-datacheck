=head1 LICENSE

Copyright [2018-2020] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CheckConservationScorePerBlock;

use warnings;
use strict;

use Moose;
use Bio::EnsEMBL::Utils::SqlHelper;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'CheckConservationScorePerBlock',
  DESCRIPTION => 'Multiple alignments with >3 species and >3 sequences must have a conservation score',
  GROUPS      => ['compara', 'compara_genome_alignments'],
  DB_TYPES    => ['compara'],
  TABLES      => ['conservation_score', 'dnafrag', 'genome_db', 'genomic_align', 'genomic_align_block', 'method_link', 'method_link_species_set', 'method_link_species_set_tag']
};

sub tests {
  my ($self) = @_;
  
  my $helper  = $self->dba->dbc->sql_helper;

  my $gerp_mlss_id_present = qq/
    SELECT mlss.method_link_species_set_id
    FROM method_link_species_set mlss
      JOIN method_link USING(method_link_id)
      LEFT JOIN method_link_species_set_tag mlsst ON (mlss.method_link_species_set_id = mlsst.method_link_species_set_id AND tag = "msa_mlss_id" AND value != "")
    WHERE type = "GERP_CONSERVATION_SCORE"
      AND tag IS NULL;
  /;
  
  my $desc_1 = "There are no GERP mlss without an msa_mlss_id tag";
  is_rows_zero($self->dba, $gerp_mlss_id_present, $desc_1);
  
  my $gerp_mlss_ids = qq/
    SELECT method_link_species_set_id 
    FROM method_link_species_set 
      LEFT JOIN method_link USING(method_link_id) 
      LEFT JOIN method_link_species_set_tag USING(method_link_species_set_id) 
    WHERE type = "GERP_CONSERVATION_SCORE"
      AND tag = "msa_mlss_id";
  /;

  my $gerp_mlss_array = $helper->execute_simple(-SQL => $gerp_mlss_ids);
  
  foreach my $mlss_id (@$gerp_mlss_array) {

    my $sql = qq/
      SELECT genomic_align_block.genomic_align_block_id 
      FROM genomic_align_block 
        LEFT JOIN conservation_score USING(genomic_align_block_id) 
        JOIN ( 
          SELECT genomic_align.genomic_align_block_id, COUNT(DISTINCT(dnafrag.genome_db_id)) AS gdb_count 
          FROM genomic_align 
            JOIN dnafrag USING(dnafrag_id) 
            GROUP BY genomic_align.genomic_align_block_id 
        ) t1 USING(genomic_align_block_id) 
        WHERE conservation_score.genomic_align_block_id IS NULL 
          AND genomic_align_block.method_link_species_set_id =$mlss_id AND t1.gdb_count > 3;
    /;
    my $desc_2 = "There are no genomic_align_blocks without a conservation score, for > 3 species & sequences";
    is_rows_zero($self->dba, $sql, $desc_2);
    
  }
  
}

1;

