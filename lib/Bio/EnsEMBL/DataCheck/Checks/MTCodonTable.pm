=head1 LICENSE

Copyright [2018-2020] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::MTCodonTable;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'MTCodonTable',
  DESCRIPTION    => 'MT seq region has codon table attribute',
  GROUPS         => ['core'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['attrib_type', 'coord_system', 'seq_region', 'seq_region_attrib']
};

sub skip_tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $sql = qq/
    SELECT COUNT(*) FROM
      seq_region INNER JOIN
      coord_system USING (coord_system_id) INNER JOIN
      seq_region_attrib USING (seq_region_id) INNER JOIN
      attrib_type USING (attrib_type_id)
    WHERE
      species_id = $species_id AND
      code = 'sequence_location' AND
      value = 'mitochondrial_chromosome'
  /;
  
  if (! sql_count($self->dba, $sql) ) {
    return (1, 'No mitochondrional seq_region.');
  }
}

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc = 'MT region has codon table attribute';
  my $sql  = qq/
    SELECT COUNT(*) FROM
      seq_region INNER JOIN
      coord_system USING (coord_system_id) INNER JOIN
      seq_region_attrib sra1 USING (seq_region_id) INNER JOIN
      seq_region_attrib sra2 USING (seq_region_id) INNER JOIN
      attrib_type at1 ON sra1.attrib_type_id = at1.attrib_type_id INNER JOIN
      attrib_type at2 ON sra2.attrib_type_id = at2.attrib_type_id
    WHERE
      species_id = $species_id AND
      at1.code   = 'sequence_location' AND
      sra1.value = 'mitochondrial_chromosome' AND
      at2.code   = 'codon_table'
  /;
  is_rows($self->dba, $sql, 1, $desc);
}

1;
