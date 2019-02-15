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

package Bio::EnsEMBL::DataCheck::Checks::ExperimentHasFeatureSet;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ExperimentHasFeatureSet',
  DESCRIPTION => 'All distinct experiment, epigenome and feature_type combinations are linked to a feature_set',
  GROUPS      => ['funcgen', 'ersa'],
  DB_TYPES    => ['funcgen'],
  TABLES      => ['experiment','feature_type','epigenome','peak_calling'],
};

sub tests {
  my ($self) = @_;
  my $desc = "Every distinct experiment, epigenome and feature_type combination is linked to a feature_set";
  my $sql = q/
    SELECT DISTINCT ex.experiment_id, ex.epigenome_id, ex.feature_type_id, ep.display_label, ft.name FROM 
      experiment ex JOIN 
      feature_type ft USING(feature_type_id) JOIN
      epigenome ep USING(epigenome_id) LEFT JOIN 
      peak_calling pc ON ex.epigenome_id=pc.epigenome_id AND ex.feature_type_id=pc.feature_type_id
    WHERE ft.name!='WCE' AND peak_calling_id is NULL
  /;
  is_rows_zero($self->dba, $sql, $desc);
}

1;
