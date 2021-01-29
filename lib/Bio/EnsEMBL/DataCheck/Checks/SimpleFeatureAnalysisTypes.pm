=head1 LICENSE

Copyright [2018-2021] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::SimpleFeatureAnalysisTypes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'SimpleFeatureAnalysisTypes',
  DESCRIPTION    => 'Simple features are not from analysis type gene, mrna and cds',
  GROUPS         => ['core', 'brc4_core'],
  DB_TYPES       => ['core'],
  TABLES         => ['gene', 'analysis', 'analysis_description']
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;
  $self->simple_feature_check('gene',$species_id);
  $self->simple_feature_check('mrna',$species_id);
  $self->simple_feature_check('cds',$species_id);
}

sub simple_feature_check {
  my ($self,$analysis,$species_id) = @_;

  my $desc = "Simples features are not from analysis type $analysis";
  my $diag = 'Analysis';
  my $sql  = qq/
      SELECT DISTINCT(a.logic_name) FROM 
        simple_feature s INNER JOIN
        analysis a using (analysis_id) INNER JOIN
        seq_region sr using (seq_region_id) INNER JOIN
        coord_system c using (coord_system_id)
      WHERE c.species_id = $species_id AND
        a.logic_name REGEXP '$analysis' 
    /;

  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;