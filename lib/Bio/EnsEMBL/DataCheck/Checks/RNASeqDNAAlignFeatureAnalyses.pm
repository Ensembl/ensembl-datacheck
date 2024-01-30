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

package Bio::EnsEMBL::DataCheck::Checks::RNASeqDNAAlignFeatureAnalyses;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'RNASeqDNAAlignFeatureAnalyses',
  DESCRIPTION    => 'In an RNA-seq database all DNA alignment features and related analyses are linked correctly.',
  GROUPS         => ['corelike'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['rnaseq'],
  TABLES         => ['analysis', 'dna_align_feature']
};

sub tests {
  my ($self) = @_;

  my $table = 'dna_align_feature';

  # All $table rows are linked to an analysis
  fk($self->dba, $table, 'analysis_id', 'analysis');

  my $desc_1 = "All $table rows have an analysis ending with '_daf'";
  my $sql_1  = qq/
    SELECT DISTINCT a.logic_name FROM
      analysis a INNER JOIN
      dna_align_feature daf USING (analysis_id)
    WHERE
      a.logic_name NOT LIKE "%_daf"
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);

  my $desc_2 = "All analyses ending in '_daf' are linked to $table rows";
  my $sql_2  = qq/
    SELECT DISTINCT a.logic_name FROM
      analysis a LEFT JOIN
      dna_align_feature daf USING (analysis_id)
    WHERE
      a.logic_name LIKE "%_daf" AND
      dna_align_feature_id IS NULL
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2);
}

1;
