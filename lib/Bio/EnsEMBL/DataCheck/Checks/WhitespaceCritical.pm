=head1 LICENSE

Copyright [2018-2022] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::WhitespaceCritical;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'WhitespaceCritical',
  DESCRIPTION => 'Fields do not contain carriage returns ("\r")',
  GROUPS      => ['compara', 'compara_blastocyst', 'compara_homology_annotation', 'compara_references', 'core', 'corelike', 'funcgen', 'schema', 'variation'],
  DB_TYPES    => ['cdna', 'compara', 'core', 'funcgen', 'otherfeatures', 'rnaseq', 'variation'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  my $varchar_sql = q/
    SELECT TABLE_NAME, COLUMN_NAME FROM
      INFORMATION_SCHEMA.COLUMNS
    WHERE
      TABLE_NAME IN (
        SELECT TABLE_NAME FROM
          INFORMATION_SCHEMA.TABLES
        WHERE
          TABLE_SCHEMA = database() AND
          TABLE_TYPE = 'BASE TABLE'
        ) AND
      DATA_TYPE IN ('text', 'varchar')
      AND TABLE_SCHEMA = database()
  /;
  my $varchars = $self->dba->dbc->sql_helper->execute(-SQL => $varchar_sql);

  foreach my $varchar (@$varchars) {
    my ($table, $column) = @$varchar;
    next if $table =~ /^MTMP/;

    my $desc = "Column $table.$column contains no carriage returns";
    my $diag = "Whitespace characters";
    my $sql  = qq/
      SELECT * FROM $table
      WHERE $column REGEXP '\r'
    /;
    is_rows_zero($self->dba, $sql, $desc, $diag);
  }
}

1;
