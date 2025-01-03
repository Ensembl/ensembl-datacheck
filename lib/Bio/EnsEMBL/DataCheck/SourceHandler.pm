=head1 LICENSE

# Copyright [2018-2025] EMBL-European Bioinformatics Institute
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

package Bio::EnsEMBL::DataCheck::SourceHandler;

use warnings;
use strict;

use base 'TAP::Parser::SourceHandler';

use TAP::Parser::Iterator::Array;
use TAP::Parser::IteratorFactory;
TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

sub can_handle {
  my ($class, $source) = @_;

  if ($source->meta->{is_object}) {
    if ($source->raw->isa('Bio::EnsEMBL::DataCheck::BaseCheck')) {
      return 1;
    }
  }

  return 0;
}

sub make_iterator {
  my ($class, $source) = @_;

  $source->raw->run();

  return TAP::Parser::Iterator::Array->new([split("\n", $source->raw->output)]);
}

1;
