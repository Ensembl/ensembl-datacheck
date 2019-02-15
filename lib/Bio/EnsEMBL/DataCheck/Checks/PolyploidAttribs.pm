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

package Bio::EnsEMBL::DataCheck::Checks::PolyploidAttribs;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'PolyploidAttribs',
  DESCRIPTION => 'Component genomes are annotated for polyploid genomes',
  GROUPS      => ['assembly', 'core'],
  DB_TYPES    => ['core'],
  TABLES      => ['attrib_type', 'seq_region', 'seq_region_attrib']
};

sub skip_tests {
  my ($self) = @_;

  my $mca   = $self->dba->get_adaptor('MetaContainer');
  my $value = $mca->single_value_by_key('ploidy');

  if (! defined $value || $value <= 2) {
    return (1, 'Not a polyploid genome.');
  }
}

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc_1 = 'Top-level regions have genome components';

  my $sa = $self->dba->get_adaptor('Slice');
  my $slices = $sa->fetch_all('toplevel');

  my @missing = ();
  foreach my $slice (@$slices) {
    my $atts = $slice->get_all_Attributes('genome_component');
    push @missing, $slice->seq_region_name if scalar(@$atts) == 0;
  }
  is(scalar(@missing), 0, $desc_1) || diag explain \@missing;

  my $desc_2 = 'Only top-level regions have genome components';
  my $sql  = qq/
    SELECT COUNT(*) FROM
      coord_system INNER JOIN
      seq_region USING (coord_system_id) INNER JOIN
      seq_region_attrib USING (seq_region_id) INNER JOIN
      attrib_type USING (attrib_type_id)
    WHERE
      attrib_type.code = 'genome_component' AND
      coord_system.attrib RLIKE 'default_version' AND
      coord_system.species_id = $species_id
  /;
  is(sql_count($self->dba, $sql), scalar(@$slices), $desc_2);
}

1;
