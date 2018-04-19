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

package Bio::EnsEMBL::DataCheck::Checks::AssemblyMapping;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'AssemblyMapping',
  DESCRIPTION => 'Check validity of assembly mappings.',
  GROUPS      => ['assembly', 'handover'],
  DB_TYPES    => ['core'],
  TABLES      => ['meta', 'coord_system'],
};

sub tests {
  my ($self) = @_;

  my $csa = $self->dba->get_adaptor("CoordSystem");
  my $mca = $self->dba->get_adaptor("MetaContainer");
  my $mappings = $mca->list_value_by_key('assembly.mapping');

  my $assembly_pattern = qr/([^:]+)(:(.+))?/;

  my $desc_1 = 'assembly.mapping defined and not an empty string';
  my $desc_2 = 'assembly.mapping element matches expected pattern';
  my $desc_3 = 'assembly.mapping element has valid coordinate system';

  foreach my $mapping (@$mappings) {
    ok(defined $mapping && $mapping ne '', $desc_1);

    foreach my $map_element (split(/[|#]/, $mapping)) {
      like($map_element, $assembly_pattern, $desc_2);

      my ($name, undef, $version) = $map_element =~ $assembly_pattern;

      my $cs = $csa->fetch_by_name($name, $version);

      ok(defined $cs, $desc_3);
    }
  }
}

1;
