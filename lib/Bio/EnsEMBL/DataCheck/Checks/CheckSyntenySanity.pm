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
use Bio::EnsEMBL::Utils::SqlHelper;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::Compara::DBSQL::MethodLinkSpeciesSetAdaptor;

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
  
  my $dba = $self->dba;
  my $helper = $dba->dbc->sql_helper;
  my $mlss_adap = $dba->get_MethodLinkSpeciesSetAdaptor;
  #Collect mlss_ids for synteny methods
  my $mlss_ids = $mlss_adap->fetch_all_by_method_link_type("SYNTENY");

  foreach my $mlss_id ( @$mlss_ids ) {
    my $mlss = $mlss_id->dbID;
    #Collect genome_db_ids in mlss_id
    my $gdb_sql = qq/
      SELECT genome_db_id 
        FROM method_link_species_set 
          LEFT JOIN species_set USING(species_set_id) 
      WHERE method_link_species_set_id = $mlss
    /;

    my $gdb_ids = $helper->execute_simple( -SQL => $gdb_sql );
    #Look for synteny_regions and GenomicAlignBlocks in mlss
    my $mlss_sql = qq/
      SELECT mlss2.method_link_species_set_id 
        FROM method_link_species_set mlss1, method_link_species_set mlss2, method_link ml 
      WHERE mlss1.method_link_species_set_id = $mlss
        AND mlss1.species_set_id = mlss2.species_set_id
        AND mlss2.method_link_id = ml.method_link_id 
        AND ml.class LIKE 'GenomicAlignBlock%'
    /;

    my $synteny_mlss = $helper->execute_simple( -SQL => $mlss_sql );
    #Collect dnafrag_ids longer than 1Mb with exceptions
    foreach my $gdb_id ( @$gdb_ids ) {
      my $dnafrag_sql = qq/
      SELECT dnafrag_id 
        FROM dnafrag 
      WHERE genome_db_id = $gdb_id
        AND coord_system_name IN ('chromosome', 'group')
        AND name NOT LIKE '%\\_%'
        AND name NOT LIKE '%Un%'
        AND name NOT IN ('MT') 
        AND length > 1000000
      /;

      my $dnafrag_ids = $helper->execute_simple( -SQL => $mlss_sql );
      #Check for reasonable count of synteny regions, fine if more than none
      foreach my $dnafrag_id ( @$dnafrag_ids ) {
        my $synteny_sql = qq/
          SELECT COUNT(*) 
            FROM synteny_region
              LEFT JOIN dnafrag_region USING (synteny_region_id) 
          WHERE method_link_species_set_id = $mlss
            AND dnafrag_id = $dnafrag_id
        /;
        #If no synteny regions counted, check genomic_alignment_blocks
        my $synteny_count = $helper->execute_single_result( -SQL => $synteny_sql );
        my $alignment_count = 0;
        if ( $synteny_count == 0 ) {
          foreach my $alignment_mlss ( @$synteny_mlss ) {
            my $dnafrag_count_sql = qq/
              SELECT dnafrag.name, count(*) as counter 
                FROM genomic_align ga1 
                  LEFT JOIN genomic_align ga2 USING (genomic_align_block_id)
                  LEFT JOIN dnafrag ON (ga2.dnafrag_id = dnafrag.dnafrag_id) 
              WHERE ga1.dnafrag_id = $dnafrag_id
                AND dnafrag.coord_system_name IN ('chromosome', 'group')
                AND ga1.method_link_species_set_id = $alignment_mlss
                AND ga1.dnafrag_id <> ga2.dnafrag_id 
              GROUP BY ga2.dnafrag_id
              ORDER BY count(*) DESC LIMIT 1
            /;
            my $aln_array = $helper->execute(  
              -SQL => $dnafrag_count_sql, 
              -USE_HASHREFS => 1,
              -CALLBACK     => sub {
                my $row = shift @_;
                return { dnafrag_name => $row->{name}, count => $row->{counter} };
              },
            );
            if ( ( scalar @$aln_array > 0 ) && ( @$aln_array[0]->{count} > $alignment_count ) ) {
              $alignment_count = @$aln_array[0]->{count};
            } 
          }
          #Error is reported if there are too many alignments to a dnafrag_id
          my $desc = "genome_db_id: $gdb_id dnafrag_id.$dnafrag_id has syntenies for MLSS $mlss with <1000 foreign alignments";
          cmp_ok( $alignment_count, '<', 1000, $desc );
        }
      }
    }
  }
}

1;

