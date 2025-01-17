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

package Bio::EnsEMBL::DataCheck::Checks::ProteinFeatureLength;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ProteinFeatureLength',
  DESCRIPTION => 'Protein features do not extend beyond the bounds of the translated sequence',
  GROUPS      => ['protein_features'],
  DB_TYPES    => ['core'],
  TABLES      => ['analysis', 'coord_system', 'interpro', 'protein_feature', 'seq_region', 'transcript', 'translation'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  # We can assume every translation has a NumResidues attribute,
  # because that is tested by the PepstatsAttributes datacheck.
  # exclude Alpha-fold entries from this datacheck "hit_name NOT LIKE 'AF-%'"
  my $desc = 'Protein features do not extend beyond the translation';
  my $diag = 'Hit name, translation_id';
  my $sql  = qq/
    SELECT
      hit_name, translation_id
    FROM
      protein_feature INNER JOIN
      translation_attrib USING (translation_id) INNER JOIN
      attrib_type USING (attrib_type_id)
    WHERE
      code = 'NumResidues' AND
      value < seq_end  AND 
      hit_name NOT LIKE 'AF-%';
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;
