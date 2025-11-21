=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::DisplayableSampleLocation;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'DisplayableSampleLocation',
  DESCRIPTION => 'Sample location is displayable and has web_data attached to its analysis',
  GROUPS      => ['analysis_description', 'core', 'brc4_core', 'geneset', 'meta_sample'],
  DB_TYPES    => ['core'],
  TABLES      => ['gene', 'meta', 'seq_region']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc_1 = 'Sample location metadata exists exactly once';
  my $diag_1 = 'genebuild.sample_location meta key should exist exactly once per species';
  my $sql_1  = qq/
      SELECT COUNT(*) AS count
        FROM meta
       WHERE meta_key = 'genebuild.sample_location'
         AND species_id = $species_id
      HAVING count != 1
    /;

  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  my $desc_2 = 'Sample location metadata is valid format';
  my $diag_2 = 'genebuild.sample_location format is invalid';
  my $sql_2  = qq/
      SELECT meta_id
        FROM meta
       WHERE meta_key = 'genebuild.sample_location'
         AND species_id = $species_id
         AND meta_value NOT REGEXP '^.+:[0-9]+-[0-9]+\$'
    /;

  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);

  my $desc_3 = 'Sample location coordinates are properly ordered';
  my $diag_3 = 'genebuild.sample_location start coordinate is greater than end coordinate';
  my $sql_3  = qq/
      SELECT meta_id
        FROM meta
       WHERE meta_key = 'genebuild.sample_location'
         AND species_id = $species_id
         AND CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(meta_value, ':', -1), '-', 1) AS UNSIGNED) >
             CAST(SUBSTRING_INDEX(meta_value, '-', -1) AS UNSIGNED)
    /;

  is_rows_zero($self->dba, $sql_3, $desc_3, $diag_3);

  my $desc_4 = 'Sample location references valid seq_region';
  my $diag_4 = 'genebuild.sample_location seq_region does not exist or coordinates out of bounds';
  my $sql_4  = qq/
      SELECT m.meta_id
        FROM meta m
        LEFT JOIN seq_region sr
          ON SUBSTRING_INDEX(m.meta_value, ':', 1) = sr.name
         AND CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(m.meta_value, ':', -1), '-', 1) AS UNSIGNED) >= 1
         AND CAST(SUBSTRING_INDEX(m.meta_value, '-', -1) AS UNSIGNED) <= sr.length
       WHERE m.meta_key = 'genebuild.sample_location'
         AND m.species_id = $species_id
         AND sr.seq_region_id IS NULL
    /;

  is_rows_zero($self->dba, $sql_4, $desc_4, $diag_4);

  my $desc_5 = 'Sample location contains at least one gene';
  my $diag_5 = 'genebuild.sample_location region has no genes';
  my $sql_5  = qq/
      SELECT m.meta_id
        FROM meta m
        JOIN seq_region sr
          ON SUBSTRING_INDEX(m.meta_value, ':', 1) = sr.name
        LEFT JOIN gene g
          ON g.seq_region_id = sr.seq_region_id
         AND g.seq_region_start <= CAST(SUBSTRING_INDEX(m.meta_value, '-', -1) AS UNSIGNED)
         AND g.seq_region_end >= CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(m.meta_value, ':', -1), '-', 1) AS UNSIGNED)
       WHERE m.meta_key = 'genebuild.sample_location'
         AND m.species_id = $species_id
         AND g.gene_id IS NULL
    /;

  is_rows_zero($self->dba, $sql_5, $desc_5, $diag_5);

}

1;

