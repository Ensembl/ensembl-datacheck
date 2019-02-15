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

package Bio::EnsEMBL::DataCheck::Checks::FeatureBounds;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'FeatureBounds',
  DESCRIPTION => 'Feature co-ordinates are within the bounds of their seq_region',
  GROUPS      => ['annotation', 'core', 'corelike'],
  DB_TYPES    => ['core', 'otherfeatures'],
  TABLES      => ['assembly_exception', 'coord_system', 'density_feature', 'ditag_feature', 'dna_align_feature', 'marker_feature', 'misc_feature', 'protein_align_feature', 'repeat_feature', 'seq_region', 'simple_feature']
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;

  $self->bounds_check('assembly_exception', $species_id);
  $self->bounds_check('density_feature', $species_id);
  $self->bounds_check('ditag_feature', $species_id);
  $self->bounds_check('dna_align_feature', $species_id);
  $self->bounds_check('karyotype', $species_id);
  $self->bounds_check('marker_feature', $species_id);
  $self->bounds_check('misc_feature', $species_id);
  $self->bounds_check('protein_align_feature', $species_id);
  $self->bounds_check('repeat_feature', $species_id);
  $self->bounds_check('simple_feature', $species_id);
}

sub bounds_check {
  my ($self, $table, $species_id) = @_;

  # We need to use SQL rather than the API, because the API will
  # not necessarily return features which are beyond slice bounds,
  # so we would miss any problems.

  my $desc = $table.'s within seq_region bounds';
  my $diag = "Out-of-bounds features in $table";
  my $sql  = qq/
    SELECT t.$table\_id FROM
      $table t INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs  USING (coord_system_id) LEFT OUTER JOIN
      assembly_exception ae USING (seq_region_id) LEFT OUTER JOIN
      (
        SELECT seq_region_id, code FROM
          seq_region_attrib INNER JOIN
          attrib_type USING (attrib_type_id)
        WHERE
          code = 'circular_seq'
      ) at ON sr.seq_region_id = at.seq_region_id
    WHERE
      (
        t.seq_region_start = 0 OR
        t.seq_region_end > sr.length
      ) AND
      cs.species_id = $species_id AND
      ae.seq_region_id IS NULL AND
      at.code IS NULL
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;
