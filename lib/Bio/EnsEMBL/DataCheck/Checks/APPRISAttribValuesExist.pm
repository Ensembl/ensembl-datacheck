=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::APPRISAttribValuesExist;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'APPRISAttribValuesExist',
  DESCRIPTION    => 'Check that APPRIS attributes exist',
  GROUPS         => ['geneset_support_level'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['attrib_type', 'transcript', 'transcript_attrib']
};

sub tests {
  my ($self) = @_;

  my $desc_1 = 'APPRIS attributes exist';
  my $sql_1  = q/
    SELECT COUNT(*) FROM
      transcript INNER JOIN
      transcript_attrib USING (transcript_id) INNER JOIN
      attrib_type USING (attrib_type_id)
    WHERE code like 'appris%'
  /;
  is_rows_nonzero($self->dba, $sql_1, $desc_1);
}

1;
