=head1 LICENSE

Copyright [2018-2021] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::SeqRegionBRC4;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'SeqRegionBRC4',
  DESCRIPTION    => 'Seq_region for BRC4 have correct attributes',
  GROUPS         => ['brc4_core'],
  DB_TYPES       => ['core'],
  TABLES         => ['attrib_type', 'coord_system', 'external_db', 'seq_region', 'seq_region_attrib', 'seq_region_synonym']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  $self->check_top_level_seq_attrib_name($species_id, 'BRC4_seq_region_name');

  # Check for INSDC accession (not systematic in case out assembly is not in sync with INSDC)
  #$self->check_seq_synonym($species_id, 'INSDC');

  # Check if there is one coord_system named primary_assembly
  my $csa = $self->dba->get_adaptor("coordsystem");
  my @coords = grep { $_->name eq 'primary_assembly' } @{ $csa->fetch_all() };

  skip 'No primary_assembly to check', 1 if @coords == 0;

  my $desc_1 = "Only one primary_assembly coord_system";
  my $diag_1 = 'Several primary assembly coords_systems';
  is(scalar(@coords), 1, $desc_1);

  my $coord = $coords[0];

  my $desc_2 = "Primary assenbly is default";
  my $diag_2 = 'Primary assembly is not default';
  is($coord->is_default, 1, $desc_2);

  my $desc_3 = "Primary assenbly is sequence level";
  my $diag_3 = 'Primary assembly is not sequence level';
  is($coord->is_sequence_level, 1, $desc_3);

  # Check that this coord_system seq_regions all have a tag
  my $coord_id = $coord->dbID;
  $self->check_seq_attrib_name_coord($species_id, $coord_id, 'coord_system_tag');
  $self->check_seq_attrib_name_coord($species_id, $coord_id, 'toplevel');
}

sub check_top_level_seq_attrib_name {
  my ($self, $species_id, $attrib_code) = @_;

  my $desc = "All toplevel seq_regions have a '$attrib_code' attribute";
  my $diag = "No attrib_name '$attrib_code' for seq_region";
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
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

sub check_seq_attrib_name_coord {
  my ($self, $species_id, $coord_id, $attrib_code) = @_;

  my $desc = "All seq_regions have a '$attrib_code' attribute";
  my $diag = "No attrib_name '$attrib_code' for seq_region";
  my $sql  = qq/
    SELECT sr.name
    FROM seq_region sr
      INNER JOIN coord_system cs USING (coord_system_id)
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

sub check_seq_synonym {
  my ($self, $species_id, $db_name) = @_;

  my $desc = "All toplevel seq_regions have a '$db_name' synonym";
  my $diag = 'No externaldb synonym for seq_region';
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
        SELECT seq_region_id, db_name FROM
          seq_region_synonym INNER JOIN
          external_db USING (external_db_id)
        WHERE
          db_name = '$db_name'
      ) srs ON sr.seq_region_id = srs.seq_region_id
    WHERE
      srs.db_name IS NULL AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;
