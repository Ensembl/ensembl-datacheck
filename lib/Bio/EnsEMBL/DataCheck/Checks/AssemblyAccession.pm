=head1 LICENSE

Copyright [2018] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::AssemblyAccession;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'AssemblyAccession',
  DESCRIPTION => 'Meta key "assembly.accession" is set.',
  GROUPS      => ['assembly', 'core_handover'],
  DB_TYPES    => ['core'],
  TABLES      => ['meta'],
};

sub tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");
  my $accs = $mca->list_value_by_key('assembly.accession');

  my $desc_1 = 'One assembly.accession value';
  is(@$accs, 1, $desc_1);

  if (@$accs == 1) {
    my $desc_2 = 'Accession has expected format';
    like($$accs[0], qr/^GCA_[0-9]+\.[0-9]+/, $desc_2);
  }
}

1;
