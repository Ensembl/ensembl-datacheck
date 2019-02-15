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

package Bio::EnsEMBL::DataCheck::Checks::DNAEmpty;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'DNAEmpty',
  DESCRIPTION => 'Core-like databases do not contain DNA sequences',
  GROUPS      => ['corelike'],
  DB_TYPES    => ['cdna', 'otherfeatures', 'rnaseq'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  my $desc = 'dna table is empty';
  my $sql  = 'SELECT COUNT(*) FROM dna';
  is_rows_zero($self->dba, $sql, $desc);
}

1;

