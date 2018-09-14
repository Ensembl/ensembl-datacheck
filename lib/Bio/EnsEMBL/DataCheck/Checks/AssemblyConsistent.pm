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

package Bio::EnsEMBL::DataCheck::Checks::AssemblyConsistent;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'AssemblyConsistent',
  DESCRIPTION => 'Assembly is the same in core and core-like databases',
  GROUPS      => ['assembly', 'core_handover'],
  DB_TYPES    => ['cdna', 'otherfeatures', 'rnaseq'],
  TABLES      => ['assembly', 'seq_region'],
  PER_DB      => 1,
};

sub tests {
  my ($self) = @_;
  my $core_dba = $self->get_dba($self->species, 'core');

  if (! defined $core_dba) {
    fail("Core database found in registry");
  } else {
    my $db_type = $self->dba->group;
    my $desc = "assembly table has same number of rows in core and $db_type databases";
    my $sql  = q/
      SELECT cs.name, COUNT(*) FROM
        assembly a INNER JOIN
        seq_region sr ON a.asm_seq_region_id = sr.seq_region_id INNER JOIN
        coord_system cs USING (coord_system_id)
      WHERE sr.name NOT LIKE 'LRG%'
      GROUP BY cs.name
    /;
    row_subtotals($self->dba, $core_dba, $sql, undef, 1, $desc);
  }
}

1;
