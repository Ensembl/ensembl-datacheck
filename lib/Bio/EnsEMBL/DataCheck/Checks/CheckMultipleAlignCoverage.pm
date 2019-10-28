=head1 LICENSE

Copyright [2018-2019] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CheckMultipleAlignCoverage;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::Utils::SqlHelper;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'CheckMultipleAlignCoverage',
  DESCRIPTION => 'Coverage for a multiple whole genome alignment MLSS matches the coverage recorded in the  mlss_tag table',
  GROUPS      => ['compara', 'compara_multiple_alignments'],
  DB_TYPES    => ['compara'],
  TABLES      => ['dnafrag', 'genome_db', 'genomic_align', 'method_link', 'method_link_species_set', 'species_tree_node', 'species_tree_node_tag']
};


sub tests {
  my ($self) = @_;
    
  my $helper  = $self->dba->dbc->sql_helper;
  
  my $msa_mlss_sql = qq/
    SELECT method_link_species_set_id 
      FROM method_link_species_set 
        JOIN method_link USING(method_link_id) 
      WHERE method_link.type IN ('EPO', 'EPO_LOW_COVERAGE', 'PECAN')
    /;
  
  my $msa_mlss_array = $helper->execute_simple(-SQL => $msa_mlss_sql);
  foreach my $mlss_id (@$msa_mlss_array) {
    
    my $genomic_align_coverage_sql = qq/
    SELECT d.genome_db_id, SUM(ga.dnafrag_end-ga.dnafrag_start+1) AS genomic_align_coverage 
      FROM genomic_align ga 
        JOIN dnafrag d USING(dnafrag_id) 
      WHERE ga.method_link_species_set_id = $mlss_id 
      GROUP BY d.genome_db_id
    /;

    my $tag_coverage_sql = qq/
    SELECT n.genome_db_id, t.value AS tag_coverage, g.genomic_align_coverage 
      FROM species_tree_node n 
        JOIN species_tree_root r USING(root_id)
        JOIN species_tree_node_tag t USING(node_id) 
        JOIN ( $genomic_align_coverage_sql )g USING(genome_db_id) 
      WHERE n.genome_db_id IS NOT NULL 
        AND t.tag = 'genome_coverage' 
        AND r.method_link_species_set_id = $mlss_id
    /;

    my $msa_summary_sql = qq/
      SELECT FORMAT(AVG(IF(genomic_align_coverage >= tag_coverage, 1, 0)), '#') 
        FROM ( $tag_coverage_sql ) c
    /;

    my $desc_2 = "genomic_align coverage matches species_tree_node_tag for mlss_id: $mlss_id";

    my $summary_result = $helper->execute_single_result(-SQL => $msa_summary_sql);
    
    is($summary_result, 1, $desc_2);
    
  }
}

1;

