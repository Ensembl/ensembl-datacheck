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

package Bio::EnsEMBL::DataCheck::Checks::XrefTypes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'XrefTypes',
  DESCRIPTION    => 'Xrefs are only attached to one feature type.',
  GROUPS         => ['xref'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['external_db', 'object_xref', 'xref'],
  PER_DB         => 1,
};

sub tests {
  my ($self) = @_;

  my $desc = 'No xrefs are associated with multiple object types';
  my $diag = 'Xrefs are associated with multiple object types';
  my $sql  = q/
    SELECT external_db_id, db_name FROM
      external_db INNER JOIN
      xref USING (external_db_id) INNER JOIN
      object_xref USING (xref_id)
    GROUP BY db_name
    HAVING COUNT(DISTINCT ensembl_object_type) > 1
  /;

  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;
