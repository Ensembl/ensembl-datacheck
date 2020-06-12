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

package Bio::EnsEMBL::DataCheck::Checks::DuplicateXref;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'DuplicateXref',
  DESCRIPTION    => 'Xrefs have been added twice with different descriptions or versions',
  GROUPS         => ['xref', 'core'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['xref'],
  PER_DB         => 1,
};

sub tests {
  my ($self) = @_;

  my $desc = 'Xrefs are unique';
  my $diag = 'Xrefs have been added twice with different descriptions or versions';
  my $sql  = q/
    SELECT COUNT(*), dbprimary_acc FROM
      xref
    GROUP BY dbprimary_acc,external_db_id,info_type,info_text
    HAVING COUNT(*) > 1
  /;

  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;
