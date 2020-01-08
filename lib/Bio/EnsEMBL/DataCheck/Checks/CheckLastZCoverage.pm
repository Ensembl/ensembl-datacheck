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

package Bio::EnsEMBL::DataCheck::Checks::CheckLastZCoverage;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::Utils::SqlHelper;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'CheckLastZCoverage',
  DESCRIPTION => 'Coverage for a LastZ MLSS matches the coverage recorded in the  mlss_tag table',
  GROUPS      => ['compara', 'compara_pairwise_alignments'],
  DB_TYPES    => ['compara'],
  TABLES      => ['dnafrag', 'genome_db', 'genomic_align', 'method_link', 'method_link_species_set', 'method_link_species_set_tag', 'species_set_header']
};


sub tests {
  my ($self) = @_;
    
  my $overlap_check;
  
  if ($self->dba->get_division() =~ /plants|pan/) {
    $overlap_check = 1;
  }
  else {
    $overlap_check = "IF(x.ref_status = 'ref' AND x.species_name NOT IN ('homo_sapiens', 'mus_musculus'), 0, 1)"; #check for overlap only for vertebrates, non vertebrates always overlap=1
  }
  
  my $lastz_mlss_ids_sql = q/
    SELECT method_link_species_set_id 
      FROM method_link_species_set 
        JOIN method_link USING(method_link_id) 
      WHERE method_link.type = 'LASTZ_NET'
    /;
  
  my $helper  = $self->dba->dbc->sql_helper;
  my $lastz_mlss_ids_array = $helper->execute_simple(-SQL => $lastz_mlss_ids_sql);
  foreach my $mlss_id (@$lastz_mlss_ids_array) {
    
    #Check if the mlss_tag coverage value 'matches' the sum of all genomic_align ranges. We consider a match:
    #1. exactly the same value in cases where overlaps are not allowed
    #  1.1. in vertebrates:  reference species, but not human or mouse
    #  1.2. non-vertebrates: overlaps allowed in all species
    #2. sum of genomic_align ranges is larger than tag value when overlaps are allowed (non-ref species or ref human/mouse)
    
    my $tag_coverage_sql = qq/
      SELECT LEFT(tag, 3) AS ref_status, GROUP_CONCAT(IF(tag LIKE '\%species', value, NULL)) AS species_name,
        GROUP_CONCAT(IF(tag LIKE '\%coverage', value, NULL)) AS tag_coverage 
      FROM method_link_species_set_tag 
      WHERE (tag LIKE '\%species' OR tag LIKE '\%genome_coverage') 
        AND method_link_species_set_id = $mlss_id 
      GROUP BY LEFT(tag, 3)
    /;
    
    my $genomic_coverage_sql = qq/
      SELECT g.name, d.genome_db_id, x.tag_coverage, SUM(ga.dnafrag_end-ga.dnafrag_start+1) AS genomic_align_coverage, 
        $overlap_check AS overlaps_allowed 
        FROM genomic_align ga JOIN dnafrag d USING(dnafrag_id) JOIN genome_db g USING(genome_db_id) 
          JOIN ( $tag_coverage_sql ) x ON x.species_name = g.name 
        WHERE ga.method_link_species_set_id = $mlss_id 
        GROUP BY g.name
    /;
    
    my $lastz_summary_sql = qq/
      SELECT SUM(IF((overlaps_allowed = 0 AND tag_coverage = genomic_align_coverage) 
        OR (overlaps_allowed = 1 AND tag_coverage <= genomic_align_coverage), 1, 0)) AS coverage_ok 
      FROM ( $genomic_coverage_sql ) y
    /;
    
    my $species_set_size_sql = qq/
      SELECT ss.size 
      FROM species_set_header ss JOIN method_link_species_set m USING(species_set_id) 
      WHERE m.method_link_species_set_id = $mlss_id
    /;
    
    my $lastz_summary_result = $helper->execute_single_result(-SQL => $lastz_summary_sql);
    my $species_set_size_result = $helper->execute_single_result(-SQL => $species_set_size_sql);
  
    my $desc_1 = "genomic_align coverage = method_link_species_set_tag coverage for mlss_id: $mlss_id";
    is($lastz_summary_result, $species_set_size_result, $desc_1);
    
  }
}

1;

