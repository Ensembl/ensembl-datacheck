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

package Bio::EnsEMBL::DataCheck::Checks::SeqRegionNamesBRC4;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'SeqRegionNamesBRC4',
  DESCRIPTION    => 'Seq_region names have correct accessions and synonyms',
  GROUPS         => ['brc4_core'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['attrib_type', 'coord_system', 'external_db', 'seq_region', 'seq_region_attrib', 'seq_region_synonym']
};

sub skip_tests {
  my ($self) = @_;
  
  my $gca = $self->dba->get_adaptor("GenomeContainer");

  if (!defined $gca->get_accession) {
    return (1, 'Not an INSDC assembly.');
  }
}

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  $self->check_seq_attrib_name($species_id, 'BRC4_seq_region_name');

  # Check for INSDC accession (not systematic in case out assembly is not in sync with INSDC)
  #$self->check_seq_synonym($species_id, 'INSDC');
}

sub check_seq_attrib_name {
  my ($self, $species_id, $attrib_code) = @_;

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
