=head1 LICENSE

# Copyright [2018] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

=cut

package Bio::EnsEMBL::DataCheck::Checks::CompareBiotype;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::CompareDbCheck';

use Bio::EnsEMBL::DataCheck::Utils::DBUtils qw/is_same_counts/;

use constant {
  NAME        => 'CompareBiotype',
  DESCRIPTION => 'Check for more than 25% difference between the number of genes '.
                 'in two databases, broken down by biotype.',
  DB_TYPES    => ['core'],
  TABLES      => ['gene'],
  GROUPS      => ['handover'],
};

sub tests {
  my ($self) = @_;
  my $dba  = $self->dba;
  my $dba2 = $self->compare_dba;

  my $desc_1 = 'Consistent gene counts';
  my $sql_1  = q/
    SELECT biotype, COUNT(*) FROM gene GROUP BY biotype
  /;
  is_same_counts($dba, $dba2, $sql_1, 0.75, $desc_1);
}

1;
