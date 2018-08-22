=head1 LICENSE

Copyright [2018] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::GeneCounts;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'GeneCounts',
  DESCRIPTION => 'Check that gene counts are correct',
  GROUPS      => ['genes'],
  DB_TYPES    => ['core'],
  TABLES      => ['attrib_type', 'gene', 'seq_region', 'seq_region_attrib']
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;

  # The names of the count attributes aren't consistently derivable
  # from the names of the biotype groups. So just do a lookup.
  my %count_attribs = (
    coding     => 'coding_cnt',
    pseudogene => 'pseudogene_cnt',
    snoncoding => 'noncoding_cnt_s',
    lnoncoding => 'noncoding_cnt_l',
    mnoncoding => 'noncoding_cnt_m',
  );
  
  while (my ($biotype_group, $attrib_code) = each %count_attribs) {
    my $desc = "Counts match for $biotype_group biotypes";

    my $sql_a = qq/
      SELECT COUNT(*) FROM
        gene INNER JOIN
        biotype ON gene.biotype = biotype.name INNER JOIN
        seq_region USING (seq_region_id) INNER JOIN
        coord_system USING (coord_system_id)
      WHERE
        biotype.biotype_group = '$biotype_group' AND
        coord_system.species_id = $species_id
    /;

    my $sql_b = qq/
      SELECT COUNT(*) FROM
        seq_region INNER JOIN
        seq_region_attrib  USING (seq_region_id) INNER JOIN
        attrib_type USING (attrib_type_id) INNER JOIN
        coord_system USING (coord_system_id)
      WHERE
        attrib_type.code = '$attrib_code' AND
        coord_system.species_id = $species_id
    /;

    row_totals($self->dba, undef, $sql_a, $sql_b, 1, $desc);
  }
}

1;

