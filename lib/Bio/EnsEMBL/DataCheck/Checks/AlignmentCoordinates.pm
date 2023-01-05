=head1 LICENSE

Copyright [2018-2023] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::AlignmentCoordinates;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'AlignmentCoordinates',
  DESCRIPTION    => 'Alignment coordinates are within the length of their dnafrag',
  DATACHECK_TYPE => 'critical',
  GROUPS         => ['compara', 'compara_genome_alignments'],
  DB_TYPES       => ['compara'],
  TABLES         => ['dnafrag', 'genomic_align']
};

sub tests {
  my ($self) = @_;
  
  my $desc_1 = "All dnafrag_starts are >= 1";
  my $sql_1 = q/
    SELECT * 
      FROM genomic_align 
    WHERE dnafrag_start < 1
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);
  
  my $desc_2 = "Alignment coordinates are within the length of their dnafrag";
  my $sql_2 = q/
    SELECT * 
      FROM genomic_align ga 
        JOIN dnafrag df 
          USING (dnafrag_id) 
    WHERE ga.dnafrag_end > length
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2);
}

1;

