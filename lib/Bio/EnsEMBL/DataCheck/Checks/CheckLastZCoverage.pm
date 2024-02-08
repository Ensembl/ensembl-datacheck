=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

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
  GROUPS      => ['compara', 'compara_genome_alignments'],
  DB_TYPES    => ['compara'],
  TABLES      => ['dnafrag', 'genome_db', 'genomic_align', 'method_link', 'method_link_species_set', 'method_link_species_set_tag', 'species_set_header']
};

sub skip_tests {
  my ($self) = @_;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my $mlss = $mlss_adap->fetch_all_by_method_link_type('LASTZ_NET');
  my $db_name = $self->dba->dbc->dbname;

  if ( scalar(@$mlss) == 0 ) {
    return( 1, "There are no LASTZ MLSS in $db_name" );
  }
}

sub tests {
  my ($self) = @_;
    
  my $lastz_mlss_ids_sql = q/
    SELECT method_link_species_set_id 
      FROM method_link_species_set 
        JOIN method_link USING(method_link_id) 
      WHERE method_link.type = 'LASTZ_NET'
    /;
  
  my $helper  = $self->dba->dbc->sql_helper;
  my $lastz_mlss_ids_array = $helper->execute_simple(-SQL => $lastz_mlss_ids_sql);
  foreach my $mlss_id (@$lastz_mlss_ids_array) {
    
    my $tag_coverage_sql = qq/
      SELECT LEFT(tag, 3) AS ref_status, GROUP_CONCAT(IF(tag LIKE '\%species', value, NULL)) AS species_name,
        GROUP_CONCAT(IF(tag LIKE '\%coverage', value, NULL)) AS tag_coverage 
      FROM method_link_species_set_tag 
      WHERE (tag LIKE '\%species' OR tag LIKE '\%genome_coverage') 
        AND method_link_species_set_id = $mlss_id 
      GROUP BY LEFT(tag, 3)
    /;
    
    my $genomic_coverage_sql = qq/
      SELECT g.name, d.genome_db_id, x.tag_coverage, SUM(ga.dnafrag_end-ga.dnafrag_start+1) AS genomic_align_coverage
        FROM genomic_align ga JOIN dnafrag d USING(dnafrag_id) JOIN genome_db g USING(genome_db_id) 
          JOIN ( $tag_coverage_sql ) x ON x.species_name = g.name 
        WHERE ga.method_link_species_set_id = $mlss_id 
        GROUP BY g.name
    /;
    
    my $lastz_summary_sql = qq/
      SELECT *
      FROM ( $genomic_coverage_sql ) y
      WHERE tag_coverage > genomic_align_coverage
    /;
    
    my $desc_1 = "genomic_align coverage >= method_link_species_set_tag coverage for mlss_id: $mlss_id";
    is_rows_zero($self->dba, $lastz_summary_sql, $desc_1);
  }
}

1;

