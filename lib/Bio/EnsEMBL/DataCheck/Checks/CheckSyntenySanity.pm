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

package Bio::EnsEMBL::DataCheck::Checks::CheckSyntenySanity;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckSyntenySanity',
  DESCRIPTION    => 'Check for missing syntenies in the compara database',
  GROUPS         => ['compara', 'compara_syntenies'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['compara'],
  TABLES         => ['dnafrag', 'dnafrag_region', 'genome_db', 'genomic_align', 'method_link', 'method_link_species_set', 'synteny_region']
};

sub tests {
  my ($self) = @_;
  # Make sure the registry is loaded
  $self->registry;

  my $dba = $self->dba;
  my $helper = $dba->dbc->sql_helper;
  my $mlss_adap = $dba->get_MethodLinkSpeciesSetAdaptor;
  my $dnafrag_adap = $dba->get_DnaFragAdaptor;
  
  #Collect mlss_ids for synteny methods
  my $mlss = $mlss_adap->fetch_all_by_method_link_type("SYNTENY");

  foreach my $mlss ( @$mlss ) {
    my $mlss_id = $mlss->dbID;
    my $gab_mlss_list = $mlss->get_all_sister_mlss_by_class('GenomicAlignBlock.pairwise_alignment');
    my $gdbs = $mlss->species_set->genome_dbs;
    
    #Collect dnafrag_ids longer than 1Mb with exceptions
    foreach my $gdb ( @$gdbs ) {
      my $gdb_id = $gdb->dbID;
      my $karyo_dnafrags = $dnafrag_adap->fetch_all_karyotype_DnaFrags_by_GenomeDB($gdb);
      
      #Check for reasonable count of synteny regions, fine if more than none
      foreach my $dnafrag ( @$karyo_dnafrags ) {
        my $dnafrag_id = $dnafrag->dbID;
        my $synteny_sql = qq/
          SELECT COUNT(*) 
            FROM synteny_region
              JOIN dnafrag_region USING (synteny_region_id) 
          WHERE method_link_species_set_id = $mlss_id
            AND dnafrag_id = $dnafrag_id
        /;
        
        #If no synteny regions counted, check genomic_alignment_blocks
        my $synteny_count = $helper->execute_single_result( -SQL => $synteny_sql );
        if ( $synteny_count == 0 ) {

          foreach my $gab_mlss ( @$gab_mlss_list ) {
            my $gab_mlss_id = $gab_mlss->dbID;
            my $dnafrag_count_sql = qq/
              SELECT ga2.dnafrag_id, count(*) as count 
                FROM genomic_align ga1 
                  JOIN genomic_align ga2 USING (genomic_align_block_id)
              WHERE ga1.dnafrag_id = $dnafrag_id
                AND ga1.method_link_species_set_id = $gab_mlss_id
                AND ga1.dnafrag_id <> ga2.dnafrag_id 
              GROUP BY ga2.dnafrag_id
              ORDER BY count(*) DESC LIMIT 1
            /;
            my $aln_array = $helper->execute(  
              -SQL => $dnafrag_count_sql, 
              -USE_HASHREFS => 1,
            );
            
            next if ( scalar @$aln_array == 0 );
            
            my $desc_1 = "genome_db_id: $gdb_id (" . $gdb->name . ") dnafrag_id: $dnafrag_id has no syntenies for mlss: $mlss_id but has <1000 alignments in the genomic_align_block mlss: $gab_mlss_id with dnafrag_id: " . @$aln_array[0]->{dnafrag_id};
            
            cmp_ok( @$aln_array[0]->{count}, '<', 1000, $desc_1 );
          }
        }
      }
    }
  }
}

1;
