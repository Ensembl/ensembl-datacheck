=head1 LICENSE

# Copyright [2018] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

=cut

package Bio::EnsEMBL::DataCheck::Checks::SequenceLevel;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use Bio::EnsEMBL::DataCheck::Utils::DBUtils qw/is_query/;

use constant {
  NAME        => 'SequenceLevel',
  DESCRIPTION => 'Check that DNA is attached and only attached to sequence-level seq_regions.',
  DB_TYPES    => ['core'],
  TABLES      => ['coord_system', 'dna', 'seq_region'],
  GROUPS      => ['handover'],
};

sub tests {
  my ($self) = @_;
  my $dba = $self->dba;

  my $desc_1 = 'Contig coord_systems have non-null versions';
  my $sql_1  = q/
    SELECT COUNT(*) FROM coord_system
    WHERE name = 'contig' AND version is not NULL
  /;
  is_query($dba, 0, $sql_1, $desc_1);

  my $desc_2 = 'Coordinate systems with sequence have sequence_level attribute';
  my $sql_2  = q/
    SELECT DISTINCT cs.name FROM
      coord_system cs INNER JOIN
      seq_region s USING (coord_system_id) INNER JOIN
      dna d USING (seq_region_id) 
    WHERE cs.attrib NOT RLIKE 'sequence_level'
  /;
  my $coord_systems = $dba->dbc->sql_helper->execute_simple(-SQL => $sql_2);
  is(@$coord_systems, 0, $desc_2);
  
  foreach (@$coord_systems) {
    diag("Coordinate system $_ has seq_regions with sequence but no sequence_level attribute");
  }
}

1;
