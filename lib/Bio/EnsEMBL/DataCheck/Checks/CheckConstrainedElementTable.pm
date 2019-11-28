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

package Bio::EnsEMBL::DataCheck::Checks::CheckConstrainedElementTable;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckConstrainedElementTable',
  DESCRIPTION    => 'Each row should show a one-to-many relationship',
  GROUPS         => ['compara', 'compara_multiple_alignments'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['constrained_elements']
};

sub tests {
  my ($self) = @_;
  my $dba = $self->dba;
  
  my $desc = "All the rows in constrained_element have a one-to-many relationship for constrained_element_id";
  
  has_one_to_many($dba->dbc, "constrained_element", "constrained_element_id", $desc);
  
}

1;

