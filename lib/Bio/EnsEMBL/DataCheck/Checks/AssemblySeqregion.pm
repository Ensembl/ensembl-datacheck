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

package Bio::EnsEMBL::DataCheck::Checks::AssemblySeqregion;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'AssemblySeqregion',
  DESCRIPTION => 'Assembly and seq_region tables are consistent',
  GROUPS      => ['assembly', 'core'],
  DB_TYPES    => ['core'],
  TABLES      => ['assembly', 'coord_system', 'seq_region'],
  PER_DB      => 1,
};

sub skip_tests {
  my ($self) = @_;

  my $sql = 'SELECT COUNT(*) FROM assembly';

  if (! sql_count($self->dba, $sql) ) {
    return (1, 'No assembly.');
  }
}

sub tests {
  my ($self) = @_;

  my $desc_1 = 'coord_system table populated';
  my $sql_1  = q/
    SELECT COUNT(*) FROM coord_system
  /;
  is_rows_nonzero($self->dba, $sql_1, $desc_1);

  my $desc_2 = 'Coord system names are lower case';
  my $sql_2  = q/
    SELECT name FROM coord_system
    WHERE BINARY name <> lower(name)
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2);

  my $desc_3 = 'assembly co-ordinates have start and end > 0';
  my $sql_3  = q/
    SELECT COUNT(*) FROM assembly
    WHERE asm_start < 1 OR asm_end < 1 OR cmp_start < 1 OR cmp_end < 1
  /;
  is_rows_zero($self->dba, $sql_3, $desc_3);

  my $desc_4 = 'assembly co-ordinates have end > start';
  my $sql_4  = q/
    SELECT COUNT(*) FROM assembly
    WHERE asm_end < asm_start OR cmp_end < cmp_start
  /;
  is_rows_zero($self->dba, $sql_4, $desc_4);

  my $desc_5 = 'Assembled and component lengths consistent';
  my $sql_5  = q/
    SELECT COUNT(*) FROM assembly
    WHERE (asm_end - asm_start) <> (cmp_end - cmp_start)
  /;
  is_rows_zero($self->dba, $sql_5, $desc_5);

  my $desc_6 = 'assembly and seq_region lengths consistent';
  my $diag_6 = 'seq_region length < largest asm_end value';
  my $sql_6  = q/
    SELECT sr.name AS seq_region_name, sr.length, cs.name AS coord_system_name
    FROM
      seq_region sr INNER JOIN
      coord_system cs ON sr.coord_system_id = cs.coord_system_id INNER JOIN
      assembly a ON a.asm_seq_region_id = sr.seq_region_id
    GROUP BY a.asm_seq_region_id
    HAVING sr.length < MAX(a.asm_end)
  /;
  is_rows_zero($self->dba, $sql_6, $desc_6, $diag_6);
}

1;
