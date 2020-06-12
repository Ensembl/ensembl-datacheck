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

package Bio::EnsEMBL::DataCheck::Checks::StructuralVariationSomatic;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'StructuralVariationSomatic',
  DESCRIPTION => 'Structural variants imported from COSMIC are somatic',
  GROUPS      => ['variation'],
  DB_TYPES    => ['variation'],
  TABLES      => ['structural_variation_feature','structural_variation']
};

sub tests {
  my ($self) = @_;

  SKIP: {
    my $species = $self->species;

    skip 'Structural variants from COSMIC not expected', 1 unless $species =~ /homo_sapiens/;

    # Structural variants imported from COSMIC must have somatic status
    # Checks structural_variation_feature and structural_variation
    my $svf_somatic = 'Structural variation features from COSMIC are somatic';
    my $sql_svf  = qq/
      SELECT COUNT(*) FROM structural_variation_feature svf
      JOIN study st ON svf.study_id = st.study_id
      WHERE svf.somatic != 1 AND st.description LIKE '%cosmic%';
    /;
    is_rows_zero($self->dba, $sql_svf, $svf_somatic);

    my $sv_somatic = 'Structural variations from COSMIC are somatic';
    my $sql_sv  = qq/
      SELECT COUNT(*) FROM structural_variation sv
      JOIN study st ON sv.study_id = st.study_id
      WHERE sv.somatic != 1 AND st.description LIKE '%cosmic%';
    /;
    is_rows_zero($self->dba, $sql_sv, $sv_somatic);
  }
}

1;
