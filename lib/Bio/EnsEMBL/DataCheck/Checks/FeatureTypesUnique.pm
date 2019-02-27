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

package Bio::EnsEMBL::DataCheck::Checks::FeatureTypesUnique;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'FeatureTypesUnique',
  DESCRIPTION => 'Checks that experiments do not link to feature types that are different, but have the same name.',
  GROUPS      => ['funcgen', 'regulatory_build', 'funcgen_registration'],
  DB_TYPES    => ['funcgen']
};

sub tests {
  my $self = shift;

  my $sql = '
    select 
        feature_type.name, 
        max(feature_type_id), 
        group_concat(feature_type_id), 
        count(distinct feature_type_id) c 
    from 
        feature_type join experiment using (feature_type_id) 
    where 
        feature_type.name != "WCE" 
    group by 
        feature_type.name 
    having c>1;
  ';

  is_rows_zero(
    $self->dba, 
    $sql, 
    DESCRIPTION, 
    'Experiments link to different feature types, but both have the same name.'
  );
  return;
}

1;

