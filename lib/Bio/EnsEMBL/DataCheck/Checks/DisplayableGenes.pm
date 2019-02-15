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

package Bio::EnsEMBL::DataCheck::Checks::DisplayableGenes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'DisplayableGenes',
  DESCRIPTION    => 'Genes are displayable and have web_data attached to their analysis',
  GROUPS         => ['core', 'corelike', 'geneset'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core', 'otherfeatures', 'rnaseq', 'cdna'],
  TABLES         => ['gene', 'analysis', 'analysis_description']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc_1 = 'All genes have displayable analysis';
  my $diag_1 = 'Undisplayed analysis';
  my $sql_1  = qq/
      SELECT analysis.logic_name
        FROM gene
  INNER JOIN analysis USING (analysis_id)
  INNER JOIN analysis_description USING (analysis_id)
  INNER JOIN seq_region USING (seq_region_id)
  INNER JOIN coord_system USING (coord_system_id)
       WHERE analysis_description.displayable = 0
         AND coord_system.species_id = $species_id
    GROUP BY analysis.logic_name
      HAVING COUNT(*) > 1
    /;

  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  my $desc_2 = 'All genes have associated web_data';
  my $diag_2 = 'web_data is not set';
  my $sql_2  = qq/
      SELECT analysis.logic_name
        FROM gene
  INNER JOIN analysis USING (analysis_id)
  INNER JOIN analysis_description USING (analysis_id)
  INNER JOIN seq_region USING (seq_region_id)
  INNER JOIN coord_system USING (coord_system_id)
       WHERE analysis_description.web_data is NULL
         AND coord_system.species_id = $species_id
    GROUP BY analysis.logic_name
      HAVING COUNT(*) > 1
    /;

  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);

}

1;
