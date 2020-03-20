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

package Bio::EnsEMBL::DataCheck::Checks::DisplayLabels;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'DisplayLabels',
  DESCRIPTION    => 'Check that certain tables have display_labels set',
  GROUPS         => ['core', 'xref'],
  DATACHECK_TYPE => 'critical',
  TABLES         => ['prediction_transcript', 'simple_feature']
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;

  my $desc_1 = 'No NULL values Found in  display_label for prediction_transcript table';
  my $sql_1  = qq/
      SELECT count(*) FROM prediction_transcript pt
      INNER JOIN seq_region sr USING (seq_region_id) 
      INNER JOIN  coord_system cs USING (coord_system_id)   
      WHERE cs.species_id = $species_id
      AND pt.display_label IS NULL
  /;

  is_rows_zero($self->dba, $sql_1, $desc_1);

  my $desc_2 = 'No NULL values Found in  display_label for simple_feature table';
  my $sql_2  = qq/
      SELECT count(*) FROM simple_feature sf
      INNER JOIN seq_region sr USING (seq_region_id) 
      INNER JOIN  coord_system cs USING (coord_system_id)   
      WHERE cs.species_id = $species_id
      AND sf.display_label IS NULL
     
  /;

  is_rows_zero($self->dba, $sql_2, $desc_2);
}

1;

