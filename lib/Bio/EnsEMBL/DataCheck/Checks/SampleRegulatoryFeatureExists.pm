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

package Bio::EnsEMBL::DataCheck::Checks::SampleRegulatoryFeatureExists;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils ``;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SampleRegulatoryFeatureExists',
  DESCRIPTION => 'Current regulatory build has a sample regulatory feature',
  GROUPS      => ['funcgen', 'regulatory_build'],
  DB_TYPES    => ['funcgen'],
  TABLES      => ['regulatory_build','regulatory_feature'],
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

  my $desc = "Current regulatory build has a sample regulatory feature";
  my $sql  = qq/
    SELECT COUNT(*) FROM
      regulatory_build rb JOIN 
      regulatory_feature rf ON rb.sample_regulatory_feature_id = rf.regulatory_feature_id 
    WHERE
      rb.regulatory_build_id = rf.regulatory_build_id AND
      rf.stable_id IS NOT NULL
  /;
  is_rows_nonzero($self->dba, $sql, $desc);
}

1;

