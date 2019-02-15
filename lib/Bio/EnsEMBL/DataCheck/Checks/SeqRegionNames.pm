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

package Bio::EnsEMBL::DataCheck::Checks::SeqRegionNames;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SeqRegionNames',
  DESCRIPTION => 'Seq_region names are unique (top-level) or consistent (non-top-level)',
  GROUPS      => ['assembly', 'core'],
  DB_TYPES    => ['core'],
  TABLES      => ['attrib_type', 'coord_system', 'seq_region', 'seq_region_attrib']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc_1 = 'Top-level seq_region names are unique';
  my $diag_1 = 'Non-unique seq_region name';
  my $sql_1  = qq/
    SELECT sr1.name, cs1.name, cs1.version, cs2.name, cs2.version FROM
      seq_region sr1 INNER JOIN
      seq_region_attrib sra1 ON sr1.seq_region_id = sra1.seq_region_id INNER JOIN
      attrib_type at1 ON sra1.attrib_type_id = at1.attrib_type_id INNER JOIN
      seq_region sr2 ON sr1.name = sr2.name INNER JOIN
      seq_region_attrib sra2 ON sr2.seq_region_id = sra2.seq_region_id INNER JOIN
      attrib_type at2 ON sra2.attrib_type_id = at2.attrib_type_id INNER JOIN
      coord_system cs1 ON sr1.coord_system_id = cs1.coord_system_id INNER JOIN
      coord_system cs2 ON sr2.coord_system_id = cs2.coord_system_id
    WHERE
      cs1.coord_system_id <> cs2.coord_system_id AND
      at1.code = 'toplevel' AND
      at2.code = 'toplevel' AND
      cs1.species_id = $species_id AND
      cs2.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  my $desc_2 = 'Identically-named seq_regions have the same length';
  my $diag_2 = 'Different lengths';
  my $sql_2  = qq/
    SELECT sr1.name, cs1.name, cs1.version, cs2.name, cs2.version FROM
      seq_region sr1 INNER JOIN
      seq_region sr2 ON sr1.name = sr2.name INNER JOIN
      coord_system cs1 ON sr1.coord_system_id = cs1.coord_system_id INNER JOIN
      coord_system cs2 ON sr2.coord_system_id = cs2.coord_system_id
    WHERE
      cs1.coord_system_id <> cs2.coord_system_id AND
      sr1.length <> sr2.length AND
      cs1.attrib RLIKE 'default_version' AND
      cs2.attrib RLIKE 'default_version' AND
      cs1.species_id = $species_id AND
      cs2.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);
}

1;
