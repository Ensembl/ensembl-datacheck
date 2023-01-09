=head1 LICENSE

Copyright [2018-2022] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::MitochondriaAnnotated;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'MitochondriaAnnotated',
  DESCRIPTION    => 'Mitochondrial seq_regions have appropriate attribute',
  GROUPS         => ['assembly', 'core', 'brc4_core'],
  DB_TYPES       => ['core'],
  TABLES         => ['attrib_type', 'coord_system', 'seq_region', 'seq_region_attrib']
};

sub skip_tests {
  my ($self) = @_;

  my $sa = $self->dba->get_adaptor('Slice');

  my %mt_names = map { lc($_) => 1 } ('chrM', 'chrMT', 'MT', 'Mito', 'mitochondrion_genome');
        
  my $mt = 0;
  foreach my $mt_name (keys %mt_names) {
    my $slice = $sa->fetch_by_region('toplevel', $mt_name);
    # Need to iterate over names due to unavoidable fuzzy matching of synonyms.
    if (defined $slice && $slice->is_toplevel) {
      my @synonyms = map { $_->name } @{$slice->get_all_synonyms};
      my @names = ($slice->seq_region_name, @synonyms);
      foreach my $name (@names) {
        if (exists $mt_names{lc($name)}) {
          $mt = 1;
        }
      }
    }
  }

  if ( !$mt ) {
    return (1, 'No apparent mitochondrial seq_regions.');
  }
}

sub tests {
  my ($self) = @_;

  my $sa = $self->dba->get_adaptor('Slice');

  my @names = ('chrM', 'chrMT', 'MT', 'Mito', 'mitochondrion_genome');
  foreach my $name (@names) {
    my $slice = $sa->fetch_by_region('toplevel', $name);
    if (defined $slice) {
      my $desc_mt = "$name has mitochondrial 'sequence_location' attribute";
      my %seq_locs = map { $_->value => 1 } @{$slice->get_all_Attributes('sequence_location')};
      ok(exists $seq_locs{'mitochondrial_chromosome'}, $desc_mt);
      # If we have chromosomes, i.e, multiple seq_region with the karyotype_rank attribute set,
      # the mitochrondria must have a karyotype_rank attribute.
      # It shouldn't have the attribute in any other case
      my $chromosomes = $sa->fetch_all_karyotype;
      my $karyotype_rank = $slice->karyotype_rank;
      if (@$chromosomes > 0) {
        ok($karyotype_rank, 'Mitochondria has karyotype_rank attribute set with chromosome presents');
      }
      else {
        ok(!$karyotype_rank, 'Mitochondria has no karyotype_rank attribute with no chromosomes');
      }
    }
  }
}

1;
