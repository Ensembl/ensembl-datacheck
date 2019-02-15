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

package Bio::EnsEMBL::DataCheck::Checks::BlankEnums;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'BlankEnums',
  DESCRIPTION => 'Enum columns do not have empty string values',
  GROUPS      => ['compara', 'core', 'corelike', 'funcgen', 'schema', 'variation'],
  DB_TYPES    => ['cdna', 'compara', 'core', 'funcgen', 'otherfeatures', 'rnaseq', 'variation'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  my $enum_sql = q/
    SELECT TABLE_NAME, COLUMN_NAME FROM
      INFORMATION_SCHEMA.COLUMNS
    WHERE
      TABLE_SCHEMA = database() AND
      DATA_TYPE = 'enum'
  /;
  my $enums = $self->dba->dbc->sql_helper->execute(-SQL => $enum_sql);

  foreach my $enum (@$enums) {
    my ($table, $column) = @$enum;

    my $desc = "ENUM column $table.$column has no empty string values";
    my $sql  = qq/
      SELECT COUNT(*) FROM $table
      WHERE $column = ''
    /;
    is_rows_zero($self->dba, $sql, $desc);
  }
}

1;
