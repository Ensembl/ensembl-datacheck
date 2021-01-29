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

package Bio::EnsEMBL::DataCheck::Checks::NoDataOnGenomeComponents;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'NoDataOnGenomeComponents',
  DESCRIPTION    => 'Data is only allowed on principle genomes and not components',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_genome_alignments', 'compara_syntenies'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['constrained_element', 'dnafrag', 'dnafrag_region', 'gene_member', 'genome_db', 'genomic_align', 'seq_member']
};

sub tests {
  my ($self) = @_;
  
  my $sql_1 = q/
    SELECT * FROM genome_db 
      JOIN species_set 
        USING (genome_db_id) 
      JOIN method_link_species_set 
        USING (species_set_id) 
    WHERE genome_component IS NOT NULL 
      AND method_link_id NOT IN (401, 600);
  /;
  #The only MLSSs that are allowed to have component GenomeDBs are protein-trees (401) and species-tree (600)
  my $desc_1 = "The only MLSSs that are allowed to have component GenomeDBs are protein-trees (401) and species-tree (600)";
  is_rows_zero($self->dba, $sql_1, $desc_1);
  #The following tables have no exceptions when it comes to component_genome_dbs
  my @tables = qw(genomic_align dnafrag_region constrained_element gene_member seq_member);
  foreach my $table (@tables) {
    my $sql_2 = qq/
      SELECT * FROM genome_db 
        JOIN dnafrag 
          USING (genome_db_id) 
        JOIN $table 
          USING (dnafrag_id) 
      WHERE genome_component IS NOT NULL;
    /;
    
    my $desc_2 = "The $table table has no data assigned to component genome_db_ids";
    is_rows_zero($self->dba, $sql_2, $desc_2);
    
  }
}

1;

