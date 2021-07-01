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
  GROUPS         => ['assembly', 'core', 'ena_submission'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['attrib_type', 'coord_system', 'external_db', 'seq_region', 'seq_region_attrib', 'seq_region_synonym']
};

sub tests {
  my ($self) = @_;

  if ($self->check_insdc_assembly) {
    # For an INSDC assembly, we expect INSDC accessions to be synonyms
    # for top-level sequences; if not, the names might be the accessions,
    # which is a hard to check rigorously, but a reasonable assumption
    # is that if it looks like an accession, it probably is. 

    my $species_id = $self->dba->species_id;
    my $format = '^[A-Z]+_?[0-9]+\.[0-9\.]+$';
    $self->check_name_format($format, $species_id);
  }
}

sub check_insdc_assembly {
  my ($self) = @_;

  my $desc = 'INSDC assembly exists';
  my $gca = $self->dba->get_adaptor("GenomeContainer");

  return ok(defined $gca->get_accession, $desc);
}

sub check_name_format {
  my ($self, $format, $species_id) = @_;

  my $desc = "seq_region names (or INSDC synonyms) match the expected format";
  my $diag = 'Unmatched seq_region name';
  my $sql  = qq/
    SELECT sr.name, srs.synonym, cs.name, cs.version FROM
      seq_region sr INNER JOIN
      seq_region_attrib sra USING (seq_region_id) INNER JOIN
      attrib_type a USING (attrib_type_id) INNER JOIN
      coord_system cs USING (coord_system_id) LEFT OUTER JOIN
      (
        SELECT seq_region_id, synonym FROM
          seq_region_synonym INNER JOIN
          external_db USING (external_db_id)
        WHERE
          db_name = 'INSDC'
      ) srs ON sr.seq_region_id = srs.seq_region_id
    WHERE
      a.code = 'toplevel' AND
      sra.value = '1' AND
      sr.name NOT REGEXP '$format' AND
      srs.synonym NOT REGEXP '$format' AND
      sr.name NOT LIKE 'LRG%' AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;
