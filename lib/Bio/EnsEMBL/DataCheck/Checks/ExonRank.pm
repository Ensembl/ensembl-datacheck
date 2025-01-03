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

package Bio::EnsEMBL::DataCheck::Checks::ExonRank;

use warnings;
use strict;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ExonRank',
  DESCRIPTION => 'Exon ranks are unique and sequential',
  GROUPS      => ['core', 'brc4_core', 'corelike', 'geneset'],
  DB_TYPES    => ['core', 'otherfeatures'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  my $desc_1 = 'No duplicate exon/transcript links';
  my $sql_1  = qq/
    SELECT
      exon_id,
      transcript_id,
      GROUP_CONCAT(`rank` SEPARATOR '-')
    FROM exon_transcript
    GROUP BY exon_id, transcript_id
    HAVING COUNT(`rank`) > 1
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);

  my $desc_2 = 'Transcripts all have an exon with rank=1';
  my $sql_2  = qq/
    SELECT stable_id FROM transcript
    WHERE transcript_id NOT IN
	  (SELECT transcript_id FROM exon_transcript WHERE `rank` = 1)
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2);

  my $desc_3 = 'Exon ranks are sequential';
  my $sql_3  = qq/
    SELECT
      transcript_id,
      count(`rank`) AS exon_count,
      max(`rank`) AS max_rank
    FROM exon_transcript
    GROUP BY transcript_id
    HAVING exon_count <> max_rank;
  /;
  is_rows_zero($self->dba, $sql_3, $desc_3);
}

1;
