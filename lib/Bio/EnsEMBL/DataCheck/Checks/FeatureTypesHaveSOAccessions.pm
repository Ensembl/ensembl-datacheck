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

package Bio::EnsEMBL::DataCheck::Checks::FeatureTypesHaveSOAccessions;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'FeatureTypesHaveSOAccessions',
  DESCRIPTION => 'Checks that every feature type used by an experiment has an SO accession.',
  GROUPS      => ['funcgen', 'regulatory_build', 'funcgen_registration'],
  DB_TYPES    => ['funcgen']
};

sub tests {
  my $self = shift;

  my $sql = '
    select 
      feature_type.name 
    from 
      experiment 
      join feature_type using (feature_type_id) 
    where 
      so_accession is null 
      and feature_type.name != "WCE"
  ';

  is_rows_zero(
    $self->dba, 
    $sql, 
    DESCRIPTION, 
    'Feature type without SO accession found.'
  );
  return;
}

1;

