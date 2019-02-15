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

package Bio::EnsEMBL::DataCheck::Checks::ValidTranscripts;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ValidTranscripts',
  DESCRIPTION => 'Transcripts have translations, if appropriate',
  GROUPS      => ['core', 'corelike', 'geneset'],
  DB_TYPES    => ['core', 'otherfeatures'],
  TABLES      => ['biotype', 'coord_system', 'seq_region', 'transcript', 'translation']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;
  my $db_type = $self->dba->group;

  my $desc_1 = "Protein-coding transcripts have translations";
  my $diag_1 = "Stable ID";
  my $sql_1  = qq/
    SELECT t.stable_id FROM
      transcript t LEFT OUTER JOIN
      translation tn USING (transcript_id) INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      t.biotype = 'protein_coding' AND
      tn.translation_id IS NULL AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  my $desc_2 = "Non-protein-coding transcripts do not have translations";
  my $diag_2 = "Stable ID";
  my $sql_2  = qq/
    SELECT t.stable_id FROM
      transcript t INNER JOIN
      translation tn USING (transcript_id) INNER JOIN
      biotype b ON t.biotype = b.name INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      b.object_type = 'transcript' AND
      FIND_IN_SET('$db_type', b.db_type) AND
      b.biotype_group IN ('pseudogene', 'snoncoding', 'lnoncoding', 'mnoncoding') AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);
}

1;
