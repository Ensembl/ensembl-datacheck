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

package Bio::EnsEMBL::DataCheck::Checks::PhenotypeDescription;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'PhenotypeDescription',
  DESCRIPTION => 'Imported descriptions contain only supported characters',
  DATACHECK_TYPE => 'advisory',
  GROUPS      => ['variation_import'],
  DB_TYPES    => ['variation'],
  TABLES      => ['phenotype']
};

sub tests {
  my ($self) = @_;

  my $desc_length = 'Phenotype description length';
  my $diag_length = "Row with suspiciously short description";
  my $sql_length = qq/
      SELECT phenotype_id
      FROM phenotype
      WHERE description IS NOT NULL
      AND LENGTH(description) < 4
  /;
  is_rows_zero($self->dba, $sql_length, $desc_length, $diag_length);

  my $desc_newline = 'Phenotype description with new line';
  my $diag_newline = "Row with unsupported new line";
  my $sql_newline = qq/
      SELECT phenotype_id
      FROM phenotype
      WHERE description IS NOT NULL
      AND description LIKE '%\n%'
  /;
  is_rows_zero($self->dba, $sql_newline, $desc_newline, $diag_newline);

  my $desc_ascii = 'ASCII chars printable in description';
  my $diag_ascii = "Row with unsupported ASCII chars";
  my $sql_ascii = qq/
      SELECT phenotype_id
      FROM phenotype
      WHERE description REGEXP '[^ -;=\?-~]'
      OR LEFT(description, 1) REGEXP '[^A-Za-z0-9]'

  /;
  is_rows_zero($self->dba, $sql_ascii, $desc_ascii, $diag_ascii);

  my $desc_non_term = 'Meaningful phenotype description';
  my $diag_non_term = 'Row description is not useful';
  my $sql_non_term = qq/
      SELECT phenotype_id
      FROM phenotype
      WHERE lower(description) in ("none", "not provided", "not specified", "not in omim", "variant of unknown significance", "not_provided", "?", ".")
  /;
  is_rows_zero($self->dba, $sql_non_term, $desc_non_term, $diag_non_term);

}

1;
