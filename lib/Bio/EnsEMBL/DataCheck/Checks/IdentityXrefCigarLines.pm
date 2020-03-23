=head1 LICENSE

Copyright [2018-2020] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::IdentityXrefCigarLines;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'IdentityXrefCigarLines',
  DESCRIPTION    => 'Check that cigar lines in the identity_xref table are in the same format, as they are in the alignment tables, i.e. start with a number rather than a letter',
  GROUPS         => ['core', 'xref'],
  DATACHECK_TYPE => 'critical',
  TABLES         => ['identity_xref'],
  PER_DB         => 1
};

sub tests {

  my ($self) = @_;
  my $desc_1 = 'All cigar lines in identity_xref are in the correct format';
  my $sql_1 = qq/
   SELECT COUNT(*) FROM identity_xref 
   WHERE cigar_line REGEXP '^[MDI]'
  /;

  is_rows_zero($self->dba, $sql_1, $desc_1);

}

1;

