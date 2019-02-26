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

package Bio::EnsEMBL::DataCheck::Checks::DensityFeatures;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'DensityFeatures',
  DESCRIPTION => 'Density statistics are present and correct for chromosomal species',
  GROUPS      => ['core_statistics', 'statistics'],
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

  $self->density_types();
  $self->density_features();
}

sub density_types {
  my ($self) = @_;

  my $desc = 'Density analysis exists';

  my @logic_names = qw/
    codingdensity
    pseudogenedensity
    shortnoncodingdensity
    longnoncodingdensity
    percentgc
    percentagerepeat
  /;

  my $dta = $self->dba->get_adaptor('DensityType');

  my $density_types = $dta->fetch_all();
  my %analyses = map { $_->analysis->logic_name => 1 } @$density_types;

  foreach my $logic_name (@logic_names) {
    ok(exists $analyses{$logic_name}, "$desc ($logic_name)");
  }
}

sub density_features {
  my ($self) = @_;

  # Some seq_regions might not have genes of a particular
  # category, so we need to compare the values of count
  # attributes in order to know what to expect.
  # (The GeneCounts datacheck ensures that the attribute values are correct.)
  my %attrib_mapping = (
    codingdensity         => 'coding_cnt',
    pseudogenedensity     => 'pseudogene_cnt',
    shortnoncodingdensity => 'noncoding_cnt_s',
    longnoncodingdensity  => 'noncoding_cnt_l',
  );

  my $dfa = $self->dba->get_adaptor('DensityFeature');
  my $sa  = $self->dba->get_adaptor('Slice');

  my $slices = $sa->fetch_all_karyotype();

  foreach my $slice (@$slices) {
    my $sr_name = $slice->coord_system_name . ' ' . $slice->seq_region_name;

    $self->gc_density($dfa, $slice,
      "Density feature counts for $sr_name (percentgc)");

    $self->repeat_density($dfa, $sa, $slice,
      "Density feature counts for $sr_name (percentagerepeat)");

    foreach my $logic_name (keys %attrib_mapping) {
      my $attrib_name = $attrib_mapping{$logic_name};

      $self->attrib_density($dfa, $slice, $logic_name, $attrib_name,
        "Density feature counts for $sr_name ($logic_name)");
    }
  }
}

sub gc_density {
  my ($self, $dfa, $slice, $desc) = @_;

  # We should always have GC calcs.
  my $dfs = $dfa->fetch_all_by_Slice($slice, 'percentgc');
  ok(defined($dfs) && scalar(@$dfs), $desc);
}

sub repeat_density {
  my ($self, $dfa, $sa, $slice, $desc) = @_;

  # We should have repeat calcs if we have repeat features.
  # Retrieving this information via the API takes a colossal amount
  # of memory and time; we can only fetch all repeat features, not
  # just check for their presence. So resort to SQL.
  my $repeat_sql = 'SELECT COUNT(*) FROM repeat_feature WHERE seq_region_id = ?';
  my $sth = $sa->dbc->prepare($repeat_sql);
  $sth->execute($slice->get_seq_region_id);
  my ($count) = $sth->fetchrow_array();
  if ($count) {
    my $dfs = $dfa->fetch_all_by_Slice($slice, 'percentagerepeat');
    ok(defined($dfs) && scalar(@$dfs), $desc);
  }
}

sub attrib_density {
  my ($self, $dfa, $slice, $logic_name, $attrib_name, $desc) = @_;

  # In addition to checking that appropriate density features exist,
  # we can check that the sum of the attrib values is consistent.
  my ($attrib) = @{$slice->get_all_Attributes($attrib_name)};
  if (defined $attrib) {
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
