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

package Bio::EnsEMBL::DataCheck::Checks::ChromosomesAnnotated;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'ChromosomesAnnotated',
  DESCRIPTION    => 'Chromosomal seq_regions have appropriate attribute',
  GROUPS         => ['assembly', 'core'],
  DB_TYPES       => ['core'],
  TABLES         => ['attrib_type', 'coord_system', 'seq_region', 'seq_region_attrib']
};

sub skip_tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;

  my $sql = qq/
    SELECT COUNT(*) FROM
      coord_system cs INNER JOIN
      seq_region sr USING (coord_system_id)
    WHERE
      cs.name IN ('chromosome', 'chromosome_group', 'plasmid') AND
      cs.species_id = $species_id
  /;

  if ( sql_count($self->dba, $sql) <= 1 ) {
    return (1, 'Zero or one chromosomal seq_regions.');
  }
}

sub tests {
  my ($self) = @_;

  my $sa = $self->dba->get_adaptor('Slice');

  my @chromosomal = ('chromosome', 'chromosome_group', 'plasmid');

  foreach my $cs_name (@chromosomal) {
    my $slices = $sa->fetch_all($cs_name);
    foreach (@$slices) {
      my $sr_name = $_->seq_region_name;
      my $desc = "$cs_name $sr_name has 'karyotype_rank' attribute";
      ok($_->has_karyotype, $desc);
    }
  }
}

1;
