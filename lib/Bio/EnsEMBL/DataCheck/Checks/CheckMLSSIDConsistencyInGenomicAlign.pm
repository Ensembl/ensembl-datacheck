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

package Bio::EnsEMBL::DataCheck::Checks::CheckMLSSIDConsistencyInGenomicAlign;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckMLSSIDConsistencyInGenomicAlign',
  DESCRIPTION    => 'Check that method_link_species_set_id are the same across genomic_align and genomic_align_block',
  GROUPS         => ['compara', 'compara_multiple_alignments', 'compara_pairwise_alignments'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['genomic_align', 'genomic_align_block']
};

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;
  
  my $desc = "All method_link_species_set_ids in genomic_align and genomic_align_block are accounted for";
  my $sql = q/
    SELECT COUNT(*) 
      FROM genomic_align ga 
        LEFT JOIN genomic_align_block gab 
          USING (genomic_align_block_id) 
    WHERE ga.method_link_species_set_id != gab.method_link_species_set_id
  /;

  is_rows_zero( $dbc, $sql, $desc);
}

1;

