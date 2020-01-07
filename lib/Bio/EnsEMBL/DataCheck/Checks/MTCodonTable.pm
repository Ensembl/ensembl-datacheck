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

package Bio::EnsEMBL::DataCheck::Checks::MTCodonTable;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'MTCodonTable',
  DESCRIPTION    => 'MT seq region has codon table attribute',
  GROUPS         => ['core'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core', 'otherfeatures'],
  TABLES         => ['attrib_type', 'coord_system', 'seq_region', 'seq_region_attrib']
};

sub skip_tests {
  my ($self) = @_;

  my $sa = $self->dba->get_adaptor('Slice');

  # There's no good way to detect a mitochondrial sequence,
  # have to rely on a set of likely names.
  my @mts = ('MT', 'Mito', 'mitochondrion_genome');

  my $has_mt = 0;
  foreach my $mt ( @mts ) {
    my $slice = $sa->fetch_by_region('toplevel', $mt);
    if (defined $slice) {
      $has_mt = 1;
      last;
    }
  }
  
  if (!$has_mt) {
    return (1, 'No mitochondrional seq_region.');
  }
}

sub tests {
  my ($self) = @_;

  my $desc = 'MT region has codon table attribute';
  my @mts  = ('MT', 'Mito', 'mitochondrion_genome');

  my $sa = $self->dba->get_adaptor('Slice');

  my $has_attribute = 0;
  foreach my $mt ( @mts ) {
    my $slice = $sa->fetch_by_region('toplevel', $mt);
    if (defined $slice) {
      my $attribs = $slice->get_all_Attributes('codon_table');

      if (scalar @$attribs) {
        $has_attribute = 1;
        last;
      }
    }
  }

  ok($has_attribute, $desc);
}

1;
