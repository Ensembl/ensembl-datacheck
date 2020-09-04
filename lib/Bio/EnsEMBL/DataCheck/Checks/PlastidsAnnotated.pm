=head1 LICENSE

Copyright [2018-2020] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::PlastidsAnnotated;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'PlastidsAnnotated',
  DESCRIPTION    => 'Plastid seq_regions have appropriate attribute',
  GROUPS         => ['assembly', 'core', 'brc4_core'],
  DB_TYPES       => ['core'],
  TABLES         => ['attrib_type', 'coord_system', 'seq_region', 'seq_region_attrib']
};

sub skip_tests {
  my ($self) = @_;

  my $sa = $self->dba->get_adaptor('Slice');

  my @names = ('chrPT', 'PT');

  my $pt = 0;
  foreach my $name (@names) {
    my $slice = $sa->fetch_by_region('toplevel', $name);
    if (defined $slice) {
      $pt = 1;
      last;
    }
  }

  if ( !$pt ) {
    return (1, 'No apparent plastid seq_regions.');
  }
}

sub tests {
  my ($self) = @_;

  my $sa = $self->dba->get_adaptor('Slice');

  my @names = ('chrPT', 'PT');
  foreach my $name (@names) {
    my $slice = $sa->fetch_by_region('toplevel', $name);
    if (defined $slice) {
      my $desc_pt = "$name has 'sequence_location' attribute";
      my $attribs = $slice->get_all_Attributes('sequence_location');
      ok(scalar @$attribs, $desc_pt);
    }
  }
}

1;
