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

package Bio::EnsEMBL::DataCheck::Checks::DisplayXref;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'DisplayXref',
  DESCRIPTION    => 'Check that display_xrefs are set OK',
  GROUPS         => ['core', 'xref'],
  DATACHECK_TYPE => 'critical',
  TABLES         => ['xref'],
};

sub tests {

  my ($self) = @_;

  my $species_id = $self->dba->species_id;
  foreach my $type ("gene", "transcript"){

    my $desc_1 = "${type}s  with valid display_xref_id";
    my $sql_1  = qq/
     SELECT COUNT(*) FROM $type t
     INNER JOIN seq_region sr USING (seq_region_id) 
     INNER JOIN  coord_system cs USING (coord_system_id)   
     WHERE cs.species_id = $species_id
     AND  t.display_xref_id IS NOT NULL 
     AND  t.display_xref_id > 0;
    /;

    is_rows_nonzero($self->dba, $sql_1, $desc_1);

    my $desc_2 = "No ${type}s  with  display_xref_id set to 0";
    my $sql_2  = qq/
     SELECT COUNT(*) FROM $type t
     INNER JOIN seq_region sr USING (seq_region_id) 
     INNER JOIN  coord_system cs USING (coord_system_id)   
     WHERE cs.species_id = $species_id     
     AND t.display_xref_id = 0
    /;

    is_rows_zero($self->dba, $sql_2, $desc_2);

    my $desc_3 = "No ${type}s have display_xref_ids pointing to non-existent xrefs";
    my $sql_3  = qq/
      SELECT count(*) FROM $type t 
      INNER JOIN seq_region sr USING (seq_region_id) 
      INNER JOIN  coord_system cs USING (coord_system_id) 
      LEFT JOIN xref ON t.display_xref_id=xref.xref_id
      WHERE cs.species_id = $species_id
      AND t.display_xref_id IS NOT NULL 
      AND xref.xref_id IS NULL;
    /;

    is_rows_zero($self->dba, $sql_3, $desc_3);

  }


    my $desc_4 = "genes have display_xrefs that are from EntrezGene and are numeric";
    my $sql_4  = qq/
       SELECT COUNT(*) FROM gene g 
       INNER JOIN seq_region sr USING (seq_region_id) 
       INNER JOIN  coord_system cs USING (coord_system_id) 
       INNER JOIN xref x ON g.display_xref_id=x.xref_id 
       INNER JOIN external_db e ON e.external_db_id=x.external_db_id 
       WHERE cs.species_id = $species_id 
       AND e.db_name='EntrezGene' 
       AND x.display_label REGEXP '^[0-9]+\$';
    /;

    is_rows_zero($self->dba, $sql_4, $desc_4);

}

1;

