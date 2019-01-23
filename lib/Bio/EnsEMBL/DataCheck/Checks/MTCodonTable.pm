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
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';


use constant {
  NAME           => 'MTCodonTable',
  DESCRIPTION    => 'MT seq region had associated seq_region attribute '
    . 'and correct codon table',
  GROUPS         => ['core_handover'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['cdna', 'core', 'funcgen', 'otherfeatures', 'rnaseq', 'variation'],
  TABLES         => ['seq_region', 'seq_region_attrib']
};

sub tests {
  my ($self) = @_;

  my $desc_1 = 'MT seq_regions have associated seq_region_attrib '
    . 'using correct codon table';
  my $sql_1 = q/
      SELECT COUNT(seq_region_id)
        FROM seq_region
       WHERE name like '%MT%'
    /;

  my $sql_2 = q/
    SELECT COUNT(seq_region_attrib.seq_region_id)
      FROM attrib_type
INNER JOIN seq_region_attrib USING (attrib_type_id)
INNER JOIN seq_region USING (seq_region_id)
     WHERE attrib_type.code = 'codon_table'
       AND seq_region_attrib.value = '2'
       AND seq_region.name like '%MT%'
    /;

  row_totals($self->dba, undef, $sql_1, $sql_2, undef, $desc_1);
}

1;
