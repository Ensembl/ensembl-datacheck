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

package Bio::EnsEMBL::DataCheck::Checks::RegulatoryFeatureStableID;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'RegulatoryFeatureStableID',
  DESCRIPTION => 'Regulatory feature stable IDs are unique within a regulatory build',
  GROUPS      => ['funcgen', 'regulatory_build'],
  DB_TYPES    => ['funcgen'],
  TABLES      => ['regulatory_feature']
};

sub skip_tests {
  my ($self) = @_;

  my $sql = q/
    SELECT COUNT(name) FROM regulatory_build 
    WHERE is_current=1
  /;

  if (! sql_count($self->dba, $sql) ) {
    return (1, 'The database has no regulatory build');
  }
}

sub tests {
  my ($self) = @_;

  my $desc = "Regulatory feature stable IDs are unique";
  my $diag = "Regulatory feature";
  my $sql  = qq/
    SELECT stable_id FROM regulatory_feature
    GROUP BY regulatory_build_id, stable_id
    HAVING COUNT(*) > 1
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;
