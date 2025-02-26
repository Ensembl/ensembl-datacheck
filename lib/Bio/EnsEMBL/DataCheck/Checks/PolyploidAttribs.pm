=head1 LICENSE

Copyright [2018-2025] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::PolyploidAttribs;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

use constant {
  NAME        => 'PolyploidAttribs',
  DESCRIPTION => 'Component genomes are annotated for polyploid genomes',
  GROUPS      => ['assembly', 'core', 'brc4_core'],
  DB_TYPES    => ['core'],
  TABLES      => ['attrib_type', 'seq_region', 'seq_region_attrib']
};

sub skip_tests {
  my ($self) = @_;

  my $mca   = $self->dba->get_adaptor('MetaContainer');
  my $value = $mca->single_value_by_key('ploidy');

  my $sql  = qq/
    SELECT COUNT(*) FROM
      seq_region_attrib INNER JOIN
      attrib_type USING (attrib_type_id)
    WHERE
      attrib_type.code = 'genome_component'
      LIMIT 1
  /;
  my $subgenomes_present = sql_count($self->dba, $sql);

  if ((! defined $value || $value <= 2) && (! $subgenomes_present)) {
    return (1, 'Not a polyploid genome.');
  }
}

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc_1 = 'Top-level chromosome regions have genome components';
  my $diag_1 = 'Missing genome component';
  my $sql_1 = qq/
    SELECT sr.name FROM
      coord_system cs INNER JOIN
      seq_region sr USING (coord_system_id) INNER JOIN
      seq_region_attrib sra1 USING (seq_region_id) INNER JOIN
      attrib_type at1 ON at1.attrib_type_id = sra1.attrib_type_id AND at1.code = 'karyotype_rank' LEFT JOIN
      seq_region_attrib sra2 USING (seq_region_id) INNER JOIN
      attrib_type at2 ON at2.attrib_type_id = sra2.attrib_type_id AND at2.code = 'genome_component'
    WHERE
      sra2.value IS NULL AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  my $desc_2 = 'Only top-level regions have genome components';
  my $diag_2 = 'Non top-level region assigned to a genome component';
  my $sql_2 = qq/
    SELECT sr.name, sra1.value FROM
      coord_system cs INNER JOIN
      seq_region sr USING (coord_system_id) INNER JOIN
      seq_region_attrib sra1 USING (seq_region_id) INNER JOIN
      attrib_type at1 ON at1.attrib_type_id = sra1.attrib_type_id AND at1.code = 'genome_component' LEFT JOIN
      seq_region_attrib sra2 USING (seq_region_id) INNER JOIN
      attrib_type at2 ON at2.attrib_type_id = sra2.attrib_type_id AND at2.code = 'toplevel'
    WHERE
      sra2.value IS NULL AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);

  my $desc_3 = 'Ploidy meta key matches the number of genome components';
  my $mca   = $self->dba->get_adaptor('MetaContainer');
  my $value = $mca->single_value_by_key('ploidy');
  my $sql_3 = qq/
    SELECT DISTINCT sra2.value FROM
      coord_system cs INNER JOIN
      seq_region sr USING (coord_system_id) INNER JOIN
      seq_region_attrib sra1 USING (seq_region_id) INNER JOIN
      attrib_type at1 ON at1.attrib_type_id = sra1.attrib_type_id AND at1.code = 'karyotype_rank' INNER JOIN
      seq_region_attrib sra2 USING (seq_region_id) INNER JOIN
      attrib_type at2 ON at2.attrib_type_id = sra2.attrib_type_id AND at2.code = 'genome_component'
    WHERE
      sr.name <> 'Un' AND
      cs.species_id = $species_id
  /;
  my $num_subgenomes = sql_count($self->dba, $sql_3);
  is($value, $num_subgenomes * 2, $desc_3);
}

1;
