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

package Bio::EnsEMBL::DataCheck::Checks::CheckConservationScore;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckConservationScore',
  DESCRIPTION    => 'The MLSS for GERP_CONSERVATION_SCORE should have conservation score entries',
  GROUPS         => ['compara', 'compara_genome_alignments'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['conservation_score', 'genomic_align_block', 'method_link', 'method_link_species_set', 'method_link_species_set_tag']
};

sub skip_tests {
  my ($self) = @_;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my $mlss = $mlss_adap->fetch_all_by_method_link_type('GERP_CONSERVATION_SCORE');
  my $db_name = $self->dba->dbc->dbname;

  if ( scalar(@$mlss) == 0 ) {
    return( 1, "There are no GERP_CONSERVATION_SCORE MLSS in $db_name" );
  }
}

sub tests {
  my ($self) = @_;
  my $dba = $self->dba;
  my $mlss_adap = $dba->get_MethodLinkSpeciesSetAdaptor;
  my $mlss = $mlss_adap->fetch_all_by_method_link_type("GERP_CONSERVATION_SCORE");
  my $helper = $dba->dbc->sql_helper;
  
  foreach my $mlss ( @$mlss ) {
    my $mlss_name = $mlss->name;
    my $mlss_id = $mlss->dbID;
    my $sql_1 = qq/
      SELECT value 
        FROM method_link_species_set_tag 
      WHERE tag = "msa_mlss_id" 
        AND method_link_species_set_id = $mlss_id
    /;
    my $desc_1 = "There is an msa_mlss_id tag for $mlss_name";
    my $msa_mlss_id = $helper->execute_single_result( -SQL => $sql_1, -NO_ERROR => 1 );
    ok($msa_mlss_id, $desc_1);

    # Can't test this mlss without an msa_mlss_id
    next unless $msa_mlss_id;
    
    my $sql_2 = qq/
      SELECT COUNT(*) 
        FROM genomic_align_block 
          JOIN conservation_score 
            USING (genomic_align_block_id) 
      WHERE method_link_species_set_id = $msa_mlss_id
    /;
    
    my $desc_2 = "There are conservation scores for multiple alignment mlss_id $msa_mlss_id in $mlss_name";
    is_rows_nonzero($dba, $sql_2, $desc_2);
  
  }
}

1;

