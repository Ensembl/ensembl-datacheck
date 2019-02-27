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

package Bio::EnsEMBL::DataCheck::Checks::ControlAlignmentNamingConvention;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ControlAlignmentNamingConvention',
  DESCRIPTION => 'By convention all controls should have WCE in their name.',
  GROUPS      => ['funcgen', 'funcgen_alignments', 'regulatory_build'],
  DB_TYPES    => ['funcgen']
};

sub tests {
  my $self = shift;

  my $sql = '
    select 
      * 
    from 
      alignment 
    where 
      is_control = true 
      and name not like "%WCE%"
  ';

  is_rows_zero(
    $self->dba, 
    $sql, 
    DESCRIPTION,
    "Some control alignments don't have WCE in their name."
  );
  return;
}

1;

