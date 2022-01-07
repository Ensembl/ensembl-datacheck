=head1 LICENSE

Copyright [2018-2022] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::TranscriptVariation;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'TranscriptVariation',
  DESCRIPTION => 'TranscriptVariation data is present and correct',
  GROUPS      => ['variation_effect'],
  DB_TYPES    => ['variation'],
  TABLES      => ['transcript_variation', 'variation_feature']
};

sub tests {
  my ($self) = @_;

  my $desc_1 = 'Peptide allele string not filled with digits';
  my $sql_1 = qq/
      SELECT COUNT(*)
      FROM transcript_variation
      WHERE pep_allele_string REGEXP '^[[:digit:]]+\$'
  /;  
  is_rows_zero($self->dba, $sql_1, $desc_1);
  
  my $desc_2 = 'Consequence type is not missing';
  my $sql_2 = qq/
      SELECT COUNT(*) 
      FROM transcript_variation 
      WHERE consequence_types = ''
      OR consequence_types = 'NULL'
      OR consequence_types IS NULL
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2);

  my $desc_3 = 'Variation features with non-intergenic consequence have transcript variation';
  my $sql_3 = qq/
      SELECT COUNT(*) 
      FROM variation_feature vf 
      WHERE NOT FIND_IN_SET('intergenic_variant',vf.consequence_types) 
      AND NOT EXISTS (
        SELECT tv.transcript_variation_id 
        FROM transcript_variation tv 
        WHERE tv.variation_feature_id = vf.variation_feature_id)
    /;
    is_rows_zero($self->dba, $sql_3, $desc_3);
}

1;
