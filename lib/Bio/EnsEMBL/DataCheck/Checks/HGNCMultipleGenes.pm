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

package Bio::EnsEMBL::DataCheck::Checks::HGNCMultipleGenes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'HGNCMultipleGenes',
  DESCRIPTION    => 'Check for HGNCs that have been assigned as display labels more than one gene.',
  GROUPS         => ['core', 'xref'],
  DATACHECK_TYPE => 'advisory',
  TABLES         => ['xref']
};

sub tests {

  my ($self) = @_;
  my $species_id = $self->dba->species_id;
  my $sql_1 = qq/
     SELECT DISTINCT(x.display_label), COUNT(*) AS count FROM xref x, external_db e , gene g
     INNER JOIN seq_region sr USING (seq_region_id) 
     INNER JOIN coord_system cs USING (coord_system_id)
     WHERE e.external_db_id=x.external_db_id 
     AND cs.species_id = $species_id
     AND e.db_name LIKE 'HGNC%' 
     AND x.xref_id=g.display_xref_id 
     AND x.display_label not like '%1 to many)'
     AND g.seq_region_id NOT in (select seq_region_id FROM seq_region_attrib sa, attrib_type at WHERE at.attrib_type_id = sa.attrib_type_id AND code = 'non_ref')
     GROUP BY x.display_label
     HAVING COUNT > 1
     
  /;

  my $rows = sql_count($self->dba, $sql_1);

  if ($rows == 0){

    is_rows_zero($self->dba,
                  $sql_1,
                  "All HGNC symbols have been assigned to only one gene");

  } elsif ($rows> 0 && $rows < 500 ) {

     is_rows_nonzero($self->dba, 
                     $sql_1, 
                     "Most HGNC symbols only assigned to one gene $rows have been assigned to more than one gene");
    
  }else {

     is_rows_zero($self->dba, 
                  $sql_1, 
                  "More than $rows HGNC symbols have been assigned to more than one gene");
  }

  
}

1;

