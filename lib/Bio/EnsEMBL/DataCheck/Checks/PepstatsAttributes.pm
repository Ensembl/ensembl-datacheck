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

package Bio::EnsEMBL::DataCheck::Checks::PepstatsAttributes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'PepstatsAttributes',
  DESCRIPTION => 'All translations have peptide statistics',
  GROUPS      => ['statistics'],
  DB_TYPES    => ['core'],
  TABLES      => ['attrib_type', 'translation', 'translation_attrib']
};

sub tests {
  my ($self) = @_;

  my @codes = qw/AvgResWeight Charge IsoPoint MolecularWeight NumResidues/;

  foreach my $code (@codes) {
    my $aa     = $self->dba->get_adaptor('Attribute');
    my $attrib = $aa->fetch_by_code($code);

    my $desc_1 = "$code attribute exists";
    ok(scalar(@$attrib), $desc_1);

    my $attrib_type_id = $$attrib[0];
    my $species_id     = $self->dba->species_id;

    my $desc_2 = "All translations have $code attribute";
    my $sql_2a = qq/
      SELECT COUNT(*) FROM
        translation INNER JOIN
        transcript USING (transcript_id) INNER JOIN
        seq_region USING (seq_region_id) INNER JOIN
        coord_system USING (coord_system_id)
      WHERE
        species_id = $species_id
    /;
    my $sql_2b = qq/
      SELECT COUNT(*) FROM
        translation INNER JOIN
        translation_attrib USING (translation_id) INNER JOIN
        transcript USING (transcript_id) INNER JOIN
        seq_region USING (seq_region_id) INNER JOIN
        coord_system USING (coord_system_id) 
      WHERE
        species_id = $species_id AND
        attrib_type_id = $attrib_type_id
    /;
    row_totals($self->dba, undef, $sql_2a, $sql_2b, 1, $desc_2);
  }
}

1;

