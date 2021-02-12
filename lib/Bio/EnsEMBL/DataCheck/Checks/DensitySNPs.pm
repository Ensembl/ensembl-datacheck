=head1 LICENSE

Copyright [2018-2021] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::DensitySNPs;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'DensitySNPs',
  DESCRIPTION => 'Density statistics are present and correct for SNPs',
  GROUPS      => ['statistics', 'variation_statistics'],
  DB_TYPES    => ['core'],
  TABLES      => ['analysis', 'attrib_type', 'coord_system', 'density_feature', 'density_type', 'seq_region', 'seq_region_attrib']
};

sub skip_tests {
  my ($self) = @_;

  my $gca = $self->dba->get_adaptor('GenomeContainer');

  if ( ! $gca->has_karyotype ) {
    return (1, 'No chromosomal seq_regions.');
  }
}

sub tests {
  my ($self) = @_;

  my $dfa = $self->dba->get_adaptor('DensityFeature');
  my $sa  = $self->dba->get_adaptor('Slice');

  my $slices = $sa->fetch_all_karyotype();

  foreach my $slice (@$slices) {
    my $sr_name = $slice->coord_system_name . ' ' . $slice->seq_region_name;

    $self->attrib_density($dfa, $slice, 'snpdensity', 'SNPCount',
      "Density feature counts for $sr_name (snpdensity)");
  }
}

sub attrib_density {
  my ($self, $dfa, $slice, $logic_name, $attrib_name, $desc) = @_;

  SKIP: {
    # In addition to checking that appropriate density features exist,
    # we can check that the sum of the attrib values is consistent.
    my ($attrib) = @{$slice->get_all_Attributes($attrib_name)};

    skip 'No SNPs on seq_region', 1 unless defined $attrib;

    my $dfs = $dfa->fetch_all_by_Slice($slice, $logic_name);
    my $density_total;
    foreach my $df (@$dfs) {
      $density_total += $df->density_value();
    }

    # Use cmp because density features may overlap,
    # in which case there will be double-counting.
    cmp_ok($density_total, '>=', $attrib->value, $desc);
  }
}

1;
