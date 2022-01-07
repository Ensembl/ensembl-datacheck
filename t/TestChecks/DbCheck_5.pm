=head1 LICENSE

# Copyright [2018-2022] EMBL-European Bioinformatics Institute
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

package TestChecks::DbCheck_5;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'DbCheck_5',
  DESCRIPTION => 'Skipping DbCheck example.',
  DB_TYPES    => ['core'],
  TABLES      => ['gene', 'transcript'],
};

sub skip_tests {
  my ($self, $magic_word) = @_;
  if (defined $magic_word && $magic_word eq 'please') {
    return(1, 'All good here, thank you');
  } else {
    return;
  }
}

sub tests {
  pass();
}

1;
