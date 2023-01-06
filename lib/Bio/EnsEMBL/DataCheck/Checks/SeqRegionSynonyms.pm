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

package Bio::EnsEMBL::DataCheck::Checks::SeqRegionSynonyms;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SeqRegionSynonyms',
  DESCRIPTION => 'Seq_region synonyms do not clash with seq region names',
  GROUPS      => ['assembly', 'brc4_core', 'core'],
  DB_TYPES    => ['core'],
  TABLES      => ['attrib_type', 'coord_system', 'seq_region', 'seq_region_synonym']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc_1 = 'Seq_region synonyms are not the same as the name of other seq_regions';
  my $diag_1 = 'Clashing seq_region synonym';
  my $sql_1  = qq/
    SELECT sr1.name, sr2.name
      FROM seq_region sr1
      INNER JOIN seq_region_synonym ss1 ON sr1.seq_region_id = ss1.seq_region_id
      INNER JOIN coord_system cs1 ON sr1.coord_system_id = cs1.coord_system_id
      , seq_region sr2
      INNER JOIN seq_region_synonym ss2 ON sr2.seq_region_id = ss2.seq_region_id
      INNER JOIN coord_system cs2 ON sr2.coord_system_id = cs2.coord_system_id
    WHERE
      sr1.name = ss2.synonym
      AND sr1.seq_region_id != sr2.seq_region_id
      AND cs1.name = cs2.name
      AND cs1.version = cs2.version
      AND cs1.species_id = $species_id
      AND cs2.species_id = $species_id
    GROUP BY sr1.name, sr2.name
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);
}

1;
