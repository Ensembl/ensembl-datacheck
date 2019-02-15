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

package Bio::EnsEMBL::DataCheck::Checks::ValidTranslations;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ValidTranslations',
  DESCRIPTION => 'Translations have appropriate properties',
  GROUPS      => ['core', 'corelike', 'geneset'],
  DB_TYPES    => ['core', 'otherfeatures'],
  TABLES      => ['coord_system', 'exon', 'exon_transcript', 'seq_region', 'transcript', 'translation']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc_1 = "CDS start < CDS end for single-exon translation";
  my $diag_1 = "Translation";
  my $sql_1  = qq/
    SELECT tn.translation_id, tn.stable_id FROM
      translation tn INNER JOIN
      transcript tt USING (transcript_id) INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      tn.start_exon_id = tn.end_exon_id AND
      tn.seq_start > tn.seq_end AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  my $desc_2 = "CDS end - CDS start >= 3 for single-exon translation";
  my $diag_2 = "Translation";
  my $sql_2  = qq/
    SELECT tn.translation_id, tn.stable_id FROM
      translation tn INNER JOIN
      transcript tt USING (transcript_id) INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      tn.start_exon_id = tn.end_exon_id AND
      (tn.seq_end - tn.seq_start) + 1 < 3 AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);

  my $desc_3 = "Start of CDS defined with exon bounds";
  my $diag_3 = "Translation";
  my $sql_3  = qq/
    SELECT tn.translation_id, tn.stable_id FROM
      translation tn INNER JOIN
      exon e ON tn.start_exon_id = e.exon_id INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      (e.seq_region_end - e.seq_region_start) + 1 < tn.seq_start AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_3, $desc_3, $diag_3);

  my $desc_4 = "End of CDS defined with exon bounds";
  my $diag_4 = "Translation";
  my $sql_4  = qq/
    SELECT tn.translation_id, tn.stable_id FROM
      translation tn INNER JOIN
      exon e ON tn.end_exon_id = e.exon_id INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      (e.seq_region_end - e.seq_region_start) + 1 < tn.seq_end AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_4, $desc_4, $diag_4);

  my $desc_5 = "No premature end_phase";
  my $diag_5 = "Translation";
  my $sql_5  = qq/
    SELECT tn.translation_id, tn.stable_id FROM
      translation tn INNER JOIN
      exon e ON tn.start_exon_id = e.exon_id INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      tn.start_exon_id <> tn.end_exon_id AND
      end_phase = -1 AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_5, $desc_5, $diag_5);

  my $desc_6 = "No erroneous start phase";
  my $diag_6 = "Translation";
  my $sql_6  = qq/
    SELECT tn.translation_id, tn.stable_id FROM
      translation tn INNER JOIN
      exon e ON tn.end_exon_id = e.exon_id INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      tn.start_exon_id <> tn.end_exon_id AND
      phase = -1 AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_6, $desc_6, $diag_6);
}

1;
