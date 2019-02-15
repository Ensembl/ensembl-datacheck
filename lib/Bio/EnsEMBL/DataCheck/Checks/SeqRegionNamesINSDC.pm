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

package Bio::EnsEMBL::DataCheck::Checks::SeqRegionNamesINSDC;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'SeqRegionNamesINSDC',
  DESCRIPTION    => 'Seq_region names from INSDC are appropriately formatted and attributed',
  GROUPS         => ['assembly', 'core'],
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

  my $format = '^[A-Z]+_?[0-9]+\.[0-9\.]+$';

  $self->check_name_format('clone', $format, $species_id);
  $self->check_name_format('contig', $format, $species_id);
  $self->check_name_format('scaffold', $format, $species_id);
  $self->check_name_format('supercontig', $format, $species_id);

  $self->check_ena_attribute('contig', $format, $species_id);
}

sub check_name_format {
  my ($self, $cs_name, $format, $species_id) = @_;

  my $desc = "$cs_name seq_region names (or INSDC synonyms) match the expected format";
  my $diag = 'Unmatched seq_region name';
  my $sql  = qq/
    SELECT sr.name, srs.synonym, cs.name, cs.version FROM
      seq_region sr INNER JOIN
      coord_system cs USING (coord_system_id) LEFT OUTER JOIN
      (
        SELECT seq_region_id, synonym FROM
          seq_region_synonym INNER JOIN
          external_db USING (external_db_id)
        WHERE
          db_name = 'INSDC'
      ) srs ON sr.seq_region_id = srs.seq_region_id
    WHERE
      cs.name = '$cs_name' AND
      sr.name NOT REGEXP '$format' AND
      srs.synonym NOT REGEXP '$format' AND
      sr.name NOT LIKE 'LRG%' AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

sub check_ena_attribute {
  my ($self, $cs_name, $format, $species_id) = @_;

  my $desc = "All $cs_name seq_regions have an 'ENA' attribute";
  my $diag = 'No ENA attribute for seq_region';
  my $sql  = qq/
    SELECT sr.name, sra.value, cs.name, cs.version FROM
      seq_region sr INNER JOIN
      coord_system cs USING (coord_system_id) LEFT OUTER JOIN
      (
        SELECT seq_region_id, value FROM
          seq_region_attrib INNER JOIN
          attrib_type USING (attrib_type_id)
        WHERE
          code = 'external_db' AND
          value = 'ENA'
      ) sra ON sr.seq_region_id = sra.seq_region_id
    WHERE
      sra.value IS NULL AND
      cs.name = '$cs_name' AND
      sr.name REGEXP '$format' AND
      sr.name NOT LIKE 'LRG%' AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;
