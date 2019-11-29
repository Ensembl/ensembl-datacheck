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

package Bio::EnsEMBL::DataCheck::Checks::CheckGenomicAlignGenomeDBs;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

use Data::Dumper;
$Data::Dumper::Maxdepth=2;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckGenomicAlignGenomeDBs',
  DESCRIPTION    => 'Check all genome_dbs for each method_link_species_set is present in genomic_aligns',
  GROUPS         => ['compara', 'compara_multiple_alignments', 'compara_pairwise_alignments'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['dnafrag', 'genome_db', 'genomic_align', 'genomic_align_block', 'method_link_species_set', 'species_set']
};

sub tests {
  my ($self) = @_;
  my $dba = $self->dba;
  my $helper = $dba->dbc->sql_helper;
  my $mlss_adap = $dba->get_MethodLinkSpeciesSetAdaptor;
  my @mlss_types = qw ( PECAN EPO EPO_LOW_COVERAGE CACTUS_HAL LASTZ_NET LASTZ_PATCH);
  
  my @mlsses;
  foreach my $mlss_type ( @mlss_types ) {
    my $mlss = $mlss_adap->fetch_all_by_method_link_type($mlss_type);
    push @mlsses, @$mlss;
  }
  
  my $ancestral_sql = q/
    SELECT genome_db_id 
      FROM genome_db 
    WHERE name = "ancestral_sequences"
    /;
  my $ancestral_id = $helper->execute_single_result( -SQL => $ancestral_sql );

  foreach my $mlss ( @mlsses ) {
    my $mlss_id = $mlss->dbID;
    my $species_set = $mlss->species_set;
    my $species_set_name = $species_set->name;
    # Collect genome_db_ids in species_sets associated with gab_mlss
    my $ss_genome_dbs = $species_set->genome_dbs;
    my @ss_gdb_ids;
    foreach my $genomedb ( @$ss_genome_dbs ) {
      my $gdb_id = $genomedb->dbID;
      push @ss_gdb_ids, $gdb_id;
    }
    # Collect distinct genome_db_ids in genomic_align_block for each gab_mlss
    my $sql = qq/
    SELECT DISTINCT(genome_db_id) 
      FROM genomic_align_block 
        JOIN genomic_align 
          USING(genomic_align_block_id) 
        JOIN dnafrag 
          USING (dnafrag_id) 
    WHERE genomic_align_block.method_link_species_set_id=$mlss_id 
      AND genome_db_id != $ancestral_id
    /;
    
    my $gab_gdb_ids = $helper->execute_simple( -SQL => $sql );
    my $desc = "The genome_db_ids in the species_set $species_set_name match the genome_db_ids in the genomic_align_blocks for $mlss_id";
    # If both arrays return the same number of genome_db_ids, pass, if not find the missing/additional genome_db_ids
    cmp_ok(scalar(@ss_gdb_ids), '==', scalar(@$gab_gdb_ids), $desc) || diag explain array_diff(@ss_gdb_ids, @$gab_gdb_ids, "genome_db_ids in genomic_align_blocks", "genome_db_ids in species_set");
  }
    
}

1;

