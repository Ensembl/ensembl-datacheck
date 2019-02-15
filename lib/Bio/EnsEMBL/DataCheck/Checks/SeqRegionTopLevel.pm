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

package Bio::EnsEMBL::DataCheck::Checks::SeqRegionTopLevel;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SeqRegionTopLevel',
  DESCRIPTION => 'Top-level seq_regions are appropriately configured',
  GROUPS      => ['assembly', 'core', 'corelike', 'geneset'],
  DB_TYPES    => ['core'],
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $mca = $self->dba->get_adaptor('MetaContainer');
  my @assembly_mappings = @{ $mca->list_value_by_key('assembly.mapping') };

  if (scalar @assembly_mappings) {
    $self->tests_with_assembly($species_id);
  } else {
    $self->tests_without_assembly($species_id);
  }

  $self->gene_tests($species_id);
}

sub tests_with_assembly {
  my ($self, $species_id) = @_;

  my $desc_1 = 'Top-level seq_regions have the "top-level" attribute';
  my $diag_1 = 'Missing "toplevel" attribute';
  my $sql_1  = qq/
    SELECT DISTINCT sr.name, cs.name, cs.version FROM
      seq_region sr INNER JOIN
      coord_system cs USING (coord_system_id) LEFT OUTER JOIN
      (
        SELECT seq_region_id, code FROM
          seq_region_attrib INNER JOIN
          attrib_type USING (attrib_type_id)
        WHERE
          code = 'toplevel'
      ) at ON sr.seq_region_id = at.seq_region_id LEFT OUTER JOIN
      assembly a ON sr.seq_region_id = a.cmp_seq_region_id INNER JOIN
      assembly a2 ON sr.seq_region_id = a2.asm_seq_region_id
    WHERE
      a.cmp_seq_region_id IS NULL AND
      at.code IS NULL AND
      cs.name <> 'clone' AND
      cs.attrib RLIKE 'default_version' AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  my $desc_2 = 'No component seq_regions marked as "top-level"';
  my $diag_2 = 'Top-level seq_region';
  my $sql_2  = qq/
    SELECT sr.name, cs.name, cs.version FROM
      seq_region sr INNER JOIN
      coord_system cs USING (coord_system_id) INNER JOIN
      seq_region_attrib sra USING (seq_region_id) INNER JOIN
      attrib_type at USING (attrib_type_id) LEFT OUTER JOIN
      assembly a ON sr.seq_region_id = a.asm_seq_region_id
    WHERE
      a.asm_seq_region_id IS NULL AND
      at.code = 'toplevel' AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);
}

sub tests_without_assembly {
  my ($self, $species_id) = @_;

  my $desc = 'Top-level seq_regions have the "top-level" attribute';
  my $diag = 'Missing "toplevel" attribute';
  my $sql  = qq/
    SELECT sr.name, cs.name, cs.version FROM
      seq_region sr INNER JOIN
      coord_system cs USING (coord_system_id) LEFT OUTER JOIN
      (
        SELECT seq_region_id, code FROM
          seq_region_attrib INNER JOIN
          attrib_type USING (attrib_type_id)
        WHERE
          code = 'toplevel'
      ) at ON sr.seq_region_id = at.seq_region_id
    WHERE
      at.code IS NULL AND
      cs.attrib RLIKE 'default_version' AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

sub gene_tests {
  my ($self, $species_id) = @_;

  my $desc = 'Genes are annotated on top-level sequences';
  my $diag = 'Gene not on top-level';
  my $sql  = qq/
    SELECT g.stable_id, sr.name, cs.name, cs.version FROM
      gene g INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id) LEFT OUTER JOIN
      (
        SELECT seq_region_id, code FROM
          seq_region_attrib INNER JOIN
          attrib_type USING (attrib_type_id)
        WHERE
          code = 'toplevel'
      ) at ON sr.seq_region_id = at.seq_region_id
    WHERE
      at.code IS NULL AND
      cs.attrib RLIKE 'default_version' AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;
