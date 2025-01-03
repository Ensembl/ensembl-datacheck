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

package Bio::EnsEMBL::DataCheck::Checks::DuplicateTranscriptNames;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'DuplicateTranscriptNames',
  DESCRIPTION    => 'Protein coding Transcript Names are unique',
  GROUPS         => ['xref', 'xref_mapping'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['transcript','xref','seq_region','coord_system']
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;
  my $desc = 'Transcript Names are unique';
  my $diag = 'Number of Transcripts, display_xref_id, dbprimary_acc';
  my $sql  = qq/
    SELECT COUNT(*), x.xref_id, x.dbprimary_acc FROM
      transcript t INNER JOIN
      xref x INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id)
    WHERE t.display_xref_id=x.xref_id AND
      t.biotype = 'protein_coding' AND
      species_id = $species_id
    GROUP BY x.xref_id
    HAVING COUNT(*) > 1
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;