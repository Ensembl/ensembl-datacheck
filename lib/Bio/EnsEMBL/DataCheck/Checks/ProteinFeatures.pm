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
      analysis INNER JOIN
      protein_feature USING (analysis_id) INNER JOIN
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

  my $desc_5 = 'protein feature accessions have correct format';
  my %format = (
    cdd =>         '^cd[[:digit:]]{5}',
    gene3d =>      '^[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+',
    hamap =>       '^MF\_[[:digit:]]{5}',
    hmmpanther =>  '^PTHR[[:digit:]]{5}',
    pfam =>        '^PF[[:digit:]]{5}',
    pfscan =>      '^PS[[:digit:]]{5}',
    pirsf =>       '^PIRSF[[:digit:]]{6}',
    prints =>      '^PR[[:digit:]]{5}',
    scanprosite => '^PS[[:digit:]]{5}',
    sfld =>        '^SFLD[FGS][[:digit:]]{5}',
    smart =>       '^SM[[:digit:]]{5}',
    superfamily => '^SSF[[:digit:]]{5}',
    tigrfam =>     '^TIGR[[:digit:]]{5}',
  );
  foreach my $source (sort keys %format) {
    my $regexp = $format{$source};
    my $sql_5 = $sql." AND logic_name = '$source' AND hit_name NOT REGEXP '$regexp'";
    is_rows_zero($self->dba, $sql_5, "$source $desc_5");
  }
}

1;
