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

package Bio::EnsEMBL::DataCheck::Checks::MTCodonTable;

use warnings;
use strict;

use Moose;
use Test::More;

use Data::Dumper;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';


use constant {
  NAME           => 'MTCodonTable',
  DESCRIPTION    => 'MT seq region had associated seq_region attribute '
    . 'and correct codon table',
  GROUPS         => ['core_handover'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['cdna', 'core', 'funcgen', 'otherfeatures', 'rnaseq', 'variation'],
  TABLES         => ['seq_region', 'seq_region_attrib', 'attrib_type', 'coord_system']
};

my @mts = ('MT', 'Mito', 'mitochondrion');

sub skip_tests {
  my ($self) = @_;

  my $counter = 0;
  foreach my $mt ( @mts ) {
    my $slice = $self->dba->get_adaptor('Slice')->fetch_by_region('toplevel', $mt);
    if (!defined($slice)) {
      return (1, 'No mitochondrion seq_region.');
    }
  }
}

sub tests {

  my ($self) = @_;
  my $sa = $self->dba->get_adaptor('Slice');
  my $aa = $self->dba->get_adaptor('Attribute');
  my $code = 'codon_table';

  my $slice;
  foreach my $mt ( @mts ) {
    $slice = $sa->fetch_by_region('toplevel', $mt);
    if (defined $slice) {
      my @attribs = @{$slice->get_all_Attributes()};
      foreach my $attrib (@attribs) {
        my $desc = "$mt has MT codon table attribute";
        if ($attrib->code =~ $code) {
          ok($attrib->code, $desc);
          last;
        }
      }
    }
  }
}


1;
