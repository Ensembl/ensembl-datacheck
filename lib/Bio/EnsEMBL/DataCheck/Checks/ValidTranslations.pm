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
  GROUPS      => ['core', 'brc4_core', 'corelike', 'geneset'],
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
      (CAST(tn.seq_end AS SIGNED) - CAST(tn.seq_start AS SIGNED)) + 1 < 3 AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);

  # To prevent the next two tests from failing for genes which span
  # the origin on circular chromosomes, we test if the exon
  # seq_region_start is less than seq_region_end. Note that the
  # GeneBounds datacheck tests those values in relation to circular
  # sequence attributes, so don't need that complexity here.
  my $desc_3 = "Start of CDS defined with exon bounds";
  my $diag_3 = "Translation";
  my $sql_3  = qq/
    SELECT tn.translation_id, tn.stable_id FROM
      translation tn INNER JOIN
      exon_transcript et USING (transcript_id) INNER JOIN
      exon e USING (exon_id) INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      tn.start_exon_id = e.exon_id AND
      (CAST(e.seq_region_end AS SIGNED) - CAST(e.seq_region_start AS SIGNED)) + 1 < tn.seq_start AND
      e.seq_region_start < e.seq_region_end AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_3, $desc_3, $diag_3);

  my $desc_4 = "End of CDS defined with exon bounds";
  my $diag_4 = "Translation";
  my $sql_4  = qq/
    SELECT tn.translation_id, tn.stable_id FROM
      translation tn INNER JOIN
      exon_transcript et USING (transcript_id) INNER JOIN
      exon e USING (exon_id) INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      tn.end_exon_id = e.exon_id AND
      (CAST(e.seq_region_end AS SIGNED) - CAST(e.seq_region_start AS SIGNED)) + 1 < tn.seq_end AND
      e.seq_region_start < e.seq_region_end AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_4, $desc_4, $diag_4);

  my $desc_5 = "No premature end_phase";
  my $diag_5 = "Translation";
  my $sql_5  = qq/
    SELECT tn.translation_id, tn.stable_id FROM
      translation tn INNER JOIN
      exon_transcript et USING (transcript_id) INNER JOIN
      exon e USING (exon_id) INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      tn.start_exon_id = e.exon_id AND
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
      exon_transcript et USING (transcript_id) INNER JOIN
      exon e USING (exon_id) INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      tn.end_exon_id = e.exon_id AND
      tn.start_exon_id <> tn.end_exon_id AND
      phase = -1 AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_6, $desc_6, $diag_6);

  # The non_translating_CDS biotype is a bit odd; it is classed as
  # protein-coding, because the originating annotator says it is.
  # But for whatever reason it does not have a valid translation,
  # and we don't want to give the impression it does, or have it
  # processed by, for example, compara.
  my $desc_7 = 'Non-translating CDS transcripts do not have translations';
  my $diag_7 = "Transcript";
  my $sql_7  = qq/
    SELECT t.stable_id FROM
  	  transcript t INNER JOIN
      translation tn USING (transcript_id) INNER JOIN
      seq_region sr ON t.seq_region_id = sr.seq_region_id INNER JOIN
      coord_system cs USING (coord_system_id)
  WHERE
      t.biotype = 'nontranslating_CDS' AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_7, $desc_7, $diag_7);
}

1;
