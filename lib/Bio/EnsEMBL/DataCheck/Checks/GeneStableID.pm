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

package Bio::EnsEMBL::DataCheck::Checks::GeneStableID;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'GeneStableID',
  DESCRIPTION => 'Genes, transcripts, exons and translations have non-NULL, unique stable IDs',
  GROUPS      => ['core', 'geneset'],
  DB_TYPES    => ['core'],
  TABLES      => ['coord_system', 'exon', 'gene', 'seq_region', 'transcript', 'translation']
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;

  $self->stable_id_check('gene',       $species_id);
  $self->stable_id_check('transcript', $species_id);
  $self->stable_id_check('exon',       $species_id);

  $self->translation_stable_id_check($species_id);
}

sub stable_id_check {
  my ($self, $table, $species_id) = @_;

  my $desc_1 = $table.' table has non-NULL stable IDs';
  my $diag_1 = "Null $table.stable_id";
  my $sql_1  = qq/
    SELECT $table.stable_id FROM
      $table INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE cs.species_id = $species_id
      AND $table.stable_id IS NULL
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  my $desc_2 = $table.' table has unique stable IDs';
  my $diag_2 = "Duplicate $table.stable_id";
  my $sql_2  = qq/
    SELECT $table.stable_id FROM
      $table INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE cs.species_id = $species_id
    GROUP BY $table.stable_id
    HAVING COUNT(*) > 1
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);
}

sub translation_stable_id_check {
  my ($self, $species_id) = @_;

  my $desc_1 = 'translation table has non-NULL stable IDs';
  my $diag_1 = "Null translation.stable_id";
  my $sql_1  = qq/
    SELECT tn.stable_id FROM
      translation tn INNER JOIN
      transcript tt USING (transcript_id) INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE cs.species_id = $species_id
      AND tn.stable_id IS NULL
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  my $desc_2 = 'translation table has unique stable IDs';
  my $diag_2 = "Duplicate translation.stable_id";
  my $sql_2  = qq/
    SELECT tn.stable_id FROM
      translation tn INNER JOIN
      transcript tt USING (transcript_id) INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE cs.species_id = $species_id
    GROUP BY tn.stable_id
    HAVING COUNT(*) > 1
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);
}

1;
