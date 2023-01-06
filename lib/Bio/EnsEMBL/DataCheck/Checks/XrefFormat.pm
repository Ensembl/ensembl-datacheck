=head1 LICENSE

Copyright [2018-2023] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::XrefFormat;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'XrefFormat',
  DESCRIPTION    => 'Xref accessions, labels, and descriptions are validly formatted',
  GROUPS         => ['core', 'xref', 'xref_gene_symbol_transformer', 'xref_mapping'],
  DB_TYPES       => ['core'],
  TABLES         => ['identity_xref', 'xref'],
  PER_DB         => 1,
};

sub tests {
  my ($self) = @_;

  my $desc_1 = 'No xrefs have HTML markup in the display_label';
  my $diag_1 = 'HTML markup';
  my $sql_1  = qq/
    SELECT display_label FROM xref
    WHERE display_label LIKE '%<%>%<\/%>%'/;
  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  foreach my $column ('dbprimary_acc', 'display_label') {
    my $desc_2 = "$column has no empty string values";
    my $diag_2 = 'Empty value';
    my $sql_2  = qq/
      SELECT dbprimary_acc, display_label FROM xref
      WHERE $column = ''
    /;
    is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);
  }

  my $desc_3 = 'No xrefs display_labels have newlines, tabs or carriage returns';
  my $diag_3 = 'Non-printing character';
  my $sql_3  = qq/
    SELECT dbprimary_acc, display_label FROM xref 
    WHERE display_label REGEXP '[\n\r\t]+'
  /;
  is_rows_zero($self->dba, $sql_3, $desc_3, $diag_3);

  my $desc_4 = 'No xrefs descriptions have newlines, tabs or carriage returns';
  my $diag_4 = 'Non-printing character';
  my $sql_4  = qq/
    SELECT dbprimary_acc, display_label FROM xref 
    WHERE description REGEXP '[\n\r\t]+'
  /;
  is_rows_zero($self->dba, $sql_4, $desc_4, $diag_4);

  my $desc_5 = 'No "ECO:" blocks from Uniprot in descriptions';
  my $diag_5 = '"ECO:" blocks';
  my $sql_5  = qq/
    SELECT dbprimary_acc, display_label FROM xref  
    WHERE description like '%{ECO:%}%'
  /;
  is_rows_zero($self->dba, $sql_5, $desc_5, $diag_5);

  my $desc_6 = 'All cigar lines in identity_xref start with M, D, or I';
  my $diag_6 = 'Invalid character';
  my $sql_6  = qq/
    SELECT object_xref_id, LEFT(cigar_line, 1) AS cigar_first FROM identity_xref 
    WHERE cigar_line REGEXP '^[MDI]'
  /;
  is_rows_zero($self->dba, $sql_6, $desc_6, $diag_6);
}

1;
