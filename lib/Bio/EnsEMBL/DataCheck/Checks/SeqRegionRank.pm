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

package Bio::EnsEMBL::DataCheck::Checks::SeqRegionRank;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

use constant {
  NAME        => 'SeqRegionRank',
  DESCRIPTION => 'Chromosomes have rank 1',
  GROUPS      => ['assembly', 'core'],
  DB_TYPES    => ['core'],
  TABLES      => ['attrib_type', 'coord_system', 'seq_region', 'seq_region_attrib']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc = 'Chromosomal seq_regions have rank 1';
  my $diag = 'Rank > 1';
  my $sql  = qq/
    SELECT sr.name, cs.name, cs.version FROM
      seq_region sr INNER JOIN
      seq_region_attrib sra USING (seq_region_id) INNER JOIN
      attrib_type at USING (attrib_type_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      at.code = 'karyotype_rank' AND
      cs.rank <> 1 AND
      cs.name <> 'plasmid' AND
      cs.species_id = $species_id
  /;

  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;
