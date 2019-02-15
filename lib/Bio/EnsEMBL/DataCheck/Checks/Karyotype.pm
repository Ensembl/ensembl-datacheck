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

package Bio::EnsEMBL::DataCheck::Checks::Karyotype;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;
use List::Util qw/min max/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'Karyotype',
  DESCRIPTION    => 'Karyotype data exists for human, mouse and rat',
  GROUPS         => ['assembly'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['attrib_type', 'coord_system', 'karyotype', 'seq_region', 'seq_region_attrib']
};

sub skip_tests {
  my ($self) = @_;

  my @applicable_species = qw/
    homo_sapiens
    mus_musculus
    rattus_norvegicus
  /;

  my %applicable_species = map { $_ => 1 } @applicable_species;

  if ( ! exists $applicable_species{$self->species} ) {
    return (1, 'Karyotype not applicable.');
  }
}

sub tests {
  my ($self) = @_;

  my $sa = $self->dba->get_adaptor('Slice');

  my $cs_name = 'chromosome';

  my $slices = $sa->fetch_all($cs_name, undef, undef, 1);
  foreach my $slice (@$slices) {
    my $sr_name = $slice->seq_region_name;
    next if $sr_name eq 'MT';
    
    my $bands = $slice->get_all_KaryotypeBands;

    my $desc_1 = "$cs_name $sr_name has karyotype bands";
    ok(scalar(@$bands), $desc_1);

    my @band_starts = map {$_->seq_region_start} @$bands;
    my @band_ends   = map {$_->seq_region_end}   @$bands;

    my $desc_2 = "Karyotype bands start at start of $cs_name $sr_name";
    is(min(@band_starts), 1, $desc_2);

    my $desc_3 = "Karyotype bands end at end of $cs_name $sr_name";
    is(max(@band_ends), $slice->length, $desc_3);
  }
}

1;
