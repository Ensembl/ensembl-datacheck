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

package Bio::EnsEMBL::DataCheck::Checks::ProteinFeatures;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ProteinFeatures',
  DESCRIPTION => 'Protein features are present and correct',
  GROUPS      => ['protein_features'],
  DB_TYPES    => ['core'],
  TABLES      => ['analysis', 'coord_system', 'interpro', 'protein_feature', 'seq_region', 'transcript', 'translation']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc_1 = 'InterPro-derived protein features exist';
  my $sql_1  = qq/
    SELECT COUNT(*) FROM
      interpro INNER JOIN
      protein_feature ON interpro.id = protein_feature.hit_name INNER JOIN
      translation USING (translation_id) INNER JOIN
      transcript USING (transcript_id) INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id)
    WHERE
      coord_system.species_id = $species_id
  /;
  is_rows_nonzero($self->dba, $sql_1, $desc_1);

  my $sql = qq/
    SELECT COUNT(*) FROM
      protein_feature INNER JOIN
      translation USING (translation_id) INNER JOIN
      transcript USING (transcript_id) INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id)
    WHERE
      coord_system.species_id = $species_id
  /;

  my $desc_2 = 'Protein feature seq start <= end';
  my $sql_2  = $sql.' AND protein_feature.seq_start > protein_feature.seq_end';
  is_rows_zero($self->dba, $sql_2, $desc_2);

  my $desc_3 = 'Protein feature hit start <= end';
  my $sql_3  = $sql.' AND protein_feature.hit_start > protein_feature.hit_end';
  is_rows_zero($self->dba, $sql_3, $desc_3);

  my $desc_4 = 'Protein feature seq start > 0';
  my $sql_4  = $sql.' AND protein_feature.seq_start < 1';
  is_rows_zero($self->dba, $sql_4, $desc_4);
}

1;
