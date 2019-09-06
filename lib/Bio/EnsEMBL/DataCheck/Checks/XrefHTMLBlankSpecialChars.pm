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

package Bio::EnsEMBL::DataCheck::Checks::XrefHTMLBlankSpecialChars;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'XrefHTMLBlankSpecialChars',
  DESCRIPTION    => 'Xrefs dont have HTML markups, newlines, tabs, carriage nor blank rows',
  GROUPS         => ['xref'],
  DB_TYPES       => ['core'],
  TABLES         => ['xref'],
  PER_DB         => 1,
};

sub tests {
  my ($self) = @_;

  my $desc = 'No xrefs appear to have HTML markup in the display_label';
  my $diag = 'Display_label';
  my $sql  = qq/
    SELECT display_label FROM xref
    WHERE display_label LIKE '%<%>%<\/%>%'/;

  is_rows_zero($self->dba, $sql, $desc, $diag);

  foreach my $column ('dbprimary_acc','display_label'){
    my $desc = "$column has no empty string values";
    my $diag = 'Dbprimary_acc and Display_label';
    my $sql1  = qq/
      SELECT dbprimary_acc,display_label FROM xref
      WHERE $column = ''
    /;
    is_rows_zero($self->dba, $sql1, $desc, $diag);
  }

  $desc = 'No xrefs descriptions have newlines, tabs or carriage returns';
  $diag = 'Dbprimary_acc and Display_label';
  my $sql2  = qq/
    SELECT dbprimary_acc,display_label FROM xref 
    WHERE description like '%\r%' or description like '%\n%' or description like '%\t%'
  /;

  is_rows_zero($self->dba, $sql2, $desc, $diag);
}

1;