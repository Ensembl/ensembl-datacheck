=head1 LICENSE

Copyright [2018-2025] EMBL-European Bioinformatics Institute

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

  my %pt_names = map { lc($_) => 1 } ('chrPT', 'PT');

  my $pt = 0;
  foreach my $pt_name (keys %pt_names) {
    my $slice = $sa->fetch_by_region('toplevel', $pt_name);
    # Need to iterate over names due to unavoidable fuzzy matching of synonyms.
    if (defined $slice && $slice->is_toplevel) {
      my @synonyms = map { $_->name } @{$slice->get_all_synonyms};
      my @names = ($slice->seq_region_name, @synonyms);
      foreach my $name (@names) {
        if (exists $pt_names{lc($name)}) {
          $pt = 1;
        }
      }
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
