=head1 LICENSE

Copyright [2018-2021] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::PredictionTranscriptLabels;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'PredictionTranscriptLabels',
  DESCRIPTION    => 'Predicted transcripts have display labels',
  GROUPS         => ['annotation', 'core'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['coord_system', 'prediction_transcript', 'seq_region']
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;

  my $desc_1 = 'No NULL display_labels in prediction_transcript table';
  my $sql_1  = qq/
      SELECT count(*) FROM prediction_transcript pt
      INNER JOIN seq_region sr USING (seq_region_id) 
      INNER JOIN  coord_system cs USING (coord_system_id)   
      WHERE cs.species_id = $species_id
      AND pt.display_label IS NULL
  /;

  is_rows_zero($self->dba, $sql_1, $desc_1);
}

1;
