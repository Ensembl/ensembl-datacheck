=head1 LICENSE

Copyright [2018-2025] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::MemberStableIDClash;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'MemberStableIDClash',
  DESCRIPTION    => 'Members should not have stable ID clashes',
  GROUPS         => ['compara', 'compara_gene_trees'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['compara'],
  TABLES         => ['gene_member', 'seq_member']
};

sub skip_tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;

  my $member_count_sql = q/SELECT COUNT(*) FROM gene_member/;
  my $member_count = $dbc->sql_helper->execute_single_result( -SQL => $member_count_sql );
  if ( $member_count == 0 ) {
    return( 1, sprintf("There are no gene members in %s", $dbc->dbname) );
  }
}

sub tests {
  my ($self) = @_;

  my $desc_1 = "Case-sensitive stable ID uniqueness among gene members";
  my $sql_1 = q/
    SELECT gene_stable_id
    FROM (
      SELECT CONVERT(stable_id USING BINARY) AS gene_stable_id
      FROM gene_member
      UNION ALL
      SELECT CONVERT(CONCAT(stable_id, '.', version) USING BINARY) AS gene_stable_id
      FROM gene_member
      WHERE version > 0
    ) gene_stable_ids
    GROUP BY gene_stable_id
    HAVING COUNT(*) > 1;
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);

  my $desc_2 = "Case-sensitive stable ID uniqueness among sequence members";
  my $sql_2 = q/
    SELECT seq_stable_id
    FROM (
      SELECT CONVERT(stable_id USING BINARY) AS seq_stable_id
      FROM seq_member
      UNION ALL
      SELECT CONVERT(CONCAT(stable_id, '.', version) USING BINARY) AS seq_stable_id
      FROM seq_member
      WHERE version > 0
    ) seq_stable_ids
    GROUP BY seq_stable_id
    HAVING COUNT(*) > 1;
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2);

  my $desc_3 = "Case-insensitive stable ID uniqueness among gene members";
  my $sql_3 = q/
    SELECT gene_stable_id
    FROM (
      SELECT stable_id AS gene_stable_id
      FROM gene_member
      UNION ALL
      SELECT CONCAT(stable_id, '.', version) AS gene_stable_id
      FROM gene_member
      WHERE version > 0
    ) gene_stable_ids
    GROUP BY gene_stable_id
    HAVING COUNT(*) > 1;
  /;
  is_rows_zero($self->dba, $sql_3, $desc_3);

  my $desc_4 = "Case-insensitive stable ID uniqueness among sequence members";
  my $sql_4 = q/
    SELECT seq_stable_id
    FROM (
      SELECT stable_id AS seq_stable_id
      FROM seq_member
      UNION ALL
      SELECT CONCAT(stable_id, '.', version) AS seq_stable_id
      FROM seq_member
      WHERE version > 0
    ) seq_stable_ids
    GROUP BY seq_stable_id
    HAVING COUNT(*) > 1;
  /;
  is_rows_zero($self->dba, $sql_4, $desc_4);
}

1;
