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

package Bio::EnsEMBL::DataCheck::Checks::SeqRegionCoordSystemBRC4;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'SeqRegionCoordSystemBRC4',
  DESCRIPTION    => 'Seq_region for primary_assembly have a coord_system_tag',
  GROUPS         => ['brc4_core'],
  DB_TYPES       => ['core'],
  TABLES         => ['attrib_type', 'coord_system', 'external_db', 'seq_region', 'seq_region_attrib', 'seq_region_synonym']
};

sub tests {
  my ($self) = @_;

  # Check if there is one coord_system named primary_assembly
  my $csa = $self->dba->get_adaptor("coordsystem");
  my @coords = grep { $_->name eq 'primary_assembly' } @{ $csa->fetch_all() };

  skip 'No primary_assembly to check', 1 if @coords == 0;

  my $desc = "Only one primary_assembly coord_system";
  my $diag = 'Several primary assembly coords_systems';
  is(scalar(@coords), 1, $desc);

  # Check that this coord_system seq_regions all have a tag
  my $species_id = $self->dba->species_id;
  my $coord_id = $coords[0]->dbID;
  $self->check_seq_attrib_name($species_id, $coord_id, 'coord_system_tag');
}

sub check_seq_attrib_name {
  my ($self, $species_id, $coord_id, $attrib_code) = @_;

  my $desc = "All toplevel seq_regions have a '$attrib_code' attribute";
  my $diag = 'No attrib_name attribute for seq_region';
  my $sql  = qq/
    SELECT sr.name
    FROM seq_region sr
      INNER JOIN coord_system cs USING (coord_system_id)
      INNER JOIN
      (
        SELECT seq_region_id, value FROM
          seq_region_attrib INNER JOIN
          attrib_type USING (attrib_type_id)
        WHERE
          code = 'toplevel'
      ) toplevel ON sr.seq_region_id = toplevel.seq_region_id
      LEFT OUTER JOIN
      (
        SELECT seq_region_id, value FROM
          seq_region_attrib INNER JOIN
          attrib_type USING (attrib_type_id)
        WHERE
          code = '$attrib_code'
      ) sra ON sr.seq_region_id = sra.seq_region_id
    WHERE
      sra.value IS NULL AND
      cs.coord_system_id = '$coord_id' AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;
