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

package Bio::EnsEMBL::DataCheck::Checks::ExonBounds;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ExonBounds',
  DESCRIPTION => 'Exon regions are non-overlapping, and are consistent with their transcripts',
  GROUPS      => ['core', 'brc4_core', 'corelike', 'geneset'],
  DB_TYPES    => ['core', 'otherfeatures'],
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $aa = $self->dba->get_adaptor('Attribute');
  my $attrib = $aa->fetch_by_code('trans_spliced');
  my $attrib_type_id = $attrib->[0] || 0;

  my $sql_tables = qq/
      exon e INNER JOIN
      exon_transcript et USING (exon_id) INNER JOIN
      transcript t USING (transcript_id) INNER JOIN
      seq_region sr ON t.seq_region_id = sr.seq_region_id INNER JOIN
      coord_system cs USING (coord_system_id) LEFT OUTER JOIN
      transcript_attrib ta ON (
        t.transcript_id = ta.transcript_id AND
        ta.attrib_type_id = $attrib_type_id
      )
  /;
  my $sql_conditions = qq/
    WHERE
      cs.species_id = $species_id AND
      ta.transcript_id IS NULL
  /;
  my $exon_transcript_sql = "$sql_tables $sql_conditions";

  my $desc_1 = "Exon bounds match transcript bounds";
  my $diag_1 = "Exon bounds do not match transcript bounds";
  my $sql_1a = qq/
    SELECT t.transcript_id, t.stable_id, t.seq_region_start, t.seq_region_end FROM
    $exon_transcript_sql AND
      et.rank = 1 AND
      t.seq_region_strand = 1 AND
      e.seq_region_start <> t.seq_region_start
    /;
  my $sql_1b = qq/
    SELECT t.transcript_id, t.stable_id, t.seq_region_start, t.seq_region_end FROM
    $exon_transcript_sql AND
      et.rank = 1 AND
      t.seq_region_strand = -1 AND
      e.seq_region_end <> t.seq_region_end
    /;
  my $sql_1c = qq/
    SELECT t.transcript_id, t.stable_id, t.seq_region_start, t.seq_region_end FROM
    $sql_tables INNER JOIN
      (SELECT transcript_id, MAX(rank) AS max_rank FROM
        exon_transcript GROUP BY transcript_id) et2
      ON t.transcript_id = et2.transcript_id
    $sql_conditions AND
      et.rank = et2.max_rank AND
      t.seq_region_strand = 1 AND
      e.seq_region_end <> t.seq_region_end
    /;
  my $sql_1d = qq/
    SELECT t.transcript_id, t.stable_id, t.seq_region_start, t.seq_region_end FROM
    $sql_tables INNER JOIN
      (SELECT transcript_id, MAX(rank) AS max_rank FROM
        exon_transcript GROUP BY transcript_id) et2
      ON t.transcript_id = et2.transcript_id
    $sql_conditions AND
      et.rank = et2.max_rank AND
      t.seq_region_strand = -1 AND
      e.seq_region_start <> t.seq_region_start
    /;

  is_rows_zero($self->dba, $sql_1a, "$desc_1 (1/4)", $diag_1);
  is_rows_zero($self->dba, $sql_1b, "$desc_1 (2/4)", $diag_1);
  is_rows_zero($self->dba, $sql_1c, "$desc_1 (3/4)", $diag_1);
  is_rows_zero($self->dba, $sql_1d, "$desc_1 (4/4)", $diag_1);

  my $desc_2 = "Exon and transcript have the same strand";
  my $diag_2 = "Transcript and exon have different strands";
  my $sql_2  = qq/
    SELECT t.transcript_id, t.stable_id, e.exon_id, e.stable_id FROM
    $exon_transcript_sql
    AND (
      e.seq_region_id <> t.seq_region_id OR
      e.seq_region_strand <> t.seq_region_strand
    )
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);

  # Writing a single SQL query to get overlaps is a bit fierce, and takes
  # ages to run, so retrieve all exons and go over them in rank order.
  my $desc_3 = 'Exons do not overlap';

  my $all_exons_sql = qq/
    SELECT
      t.transcript_id,
      e.stable_id,
      e.seq_region_start,
      e.seq_region_end,
      e.seq_region_strand
    FROM
    $exon_transcript_sql
    ORDER BY et.transcript_id, et.rank
  /;

  my $helper = $self->dba->dbc->sql_helper;
  my $exon_iterator = $helper->execute(
    -SQL => $all_exons_sql,
    -ITERATOR => 1
  );

  my $last_transcript_id;
  my $last_exon_id;
  my $last_start;
  my $last_end;

  my @exon_overlaps;

  while ($exon_iterator->has_next) {
    my $exon = $exon_iterator->next;
    my ($transcript_id, $exon_id, $start, $end, $strand) = @$exon;

    if (defined $last_transcript_id && $last_transcript_id == $transcript_id) {
      if ($strand == 1) {
        if ($last_start < $start && $start < $last_end) {
          push(@exon_overlaps, "Exons $last_exon_id and $exon_id overlap ($last_end > $start)");
        }
      } else {
        if ($last_start < $end && $last_end < $end) {
          push(@exon_overlaps, "Exons $last_exon_id and $exon_id overlap ($last_start < $end)");
        }
      }
    }

    $last_transcript_id = $transcript_id;
    $last_exon_id = $exon_id;
    $last_start = $start;
    $last_end = $end;
  }

  is(scalar(@exon_overlaps), 0, $desc_3) || diag explain \@exon_overlaps;
}

1;
