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

package Bio::EnsEMBL::DataCheck::Checks::SignalControlMismatches;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SignalControlMismatches',
  DESCRIPTION => 'Checks that signals are not matched to the wrong controls.',
  GROUPS      => ['funcgen', 'regulatory_build', 'funcgen_registration'],
  DB_TYPES    => ['funcgen']
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
  my $self = shift;

  my $sql = '
    select 
      s.name, c.name
    from 
      experiment s 
      join experiment c on (
        s.control_id = c.experiment_id 
        and s.epigenome_id != c.epigenome_id
      )
  ';

  is_rows_zero(
    $self->dba, 
    $sql, 
    DESCRIPTION, 
    'Signal and control experiments mismatched.'
  );
  return;
}

1;

