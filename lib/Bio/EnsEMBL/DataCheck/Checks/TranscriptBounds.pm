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

package Bio::EnsEMBL::DataCheck::Checks::TranscriptBounds;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'TranscriptBounds',
  DESCRIPTION => 'Gene and transcript bounds are consistent',
  GROUPS      => ['core', 'corelike', 'geneset'],
  DB_TYPES    => ['core', 'otherfeatures'],
  TABLES      => ['attrib_type', 'coord_system', 'gene', 'seq_region', 'transcript', 'transcript_attrib']
};

sub tests {
  my ($self) = @_;
  
  my $species_id = $self->dba->species_id;

  my $desc_1 = "Gene co-ordinates are the same as the transcript extremities";
  my $diag_1 = "Gene";
  my $sql_1  = qq/
    SELECT g.stable_id, g.seq_region_start, g.seq_region_end FROM
      gene g INNER JOIN
      transcript t USING (gene_id) INNER JOIN
      seq_region sr ON g.seq_region_id = sr.seq_region_id INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      cs.species_id = $species_id
    GROUP BY
      g.stable_id
    HAVING
      MIN(t.seq_region_start) <> g.seq_region_start OR
      MAX(t.seq_region_end) <> g.seq_region_end
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  my $desc_2 = "Genes are on same seq_region and strand as their transcripts";
  my $diag_2 = "Gene and transcript";
  my $sql_2  = qq/
    SELECT g.stable_id, t.stable_id FROM
      gene g INNER JOIN
      transcript t USING (gene_id) INNER JOIN
      seq_region sr ON g.seq_region_id = sr.seq_region_id INNER JOIN
      coord_system cs USING (coord_system_id) LEFT OUTER JOIN
      (
        SELECT transcript_id, code FROM
          transcript_attrib INNER JOIN
          attrib_type USING (attrib_type_id)
        WHERE
          code = 'trans_spliced'
      ) at ON t.transcript_id = at.transcript_id
    WHERE
      cs.species_id = $species_id AND
      at.code IS NULL AND
      (
        g.seq_region_id <> t.seq_region_id OR
        g.seq_region_strand <> t.seq_region_strand
      )
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);
}

1;
