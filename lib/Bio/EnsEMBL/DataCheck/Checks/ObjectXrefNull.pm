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

package Bio::EnsEMBL::DataCheck::Checks::ObjectXrefNull;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'ObjectXrefNull',
  DESCRIPTION    => 'Object_xrefs should be linked to an analysis',
  GROUPS         => ['brc4_core', 'core', 'xref'],
  DATACHECK_TYPE => 'advisory',
  TABLES         => ['object_xref']
};

sub tests {
  my ($self) = @_;

  # In theory, all object_xrefs should be linked to an analysis,
  # so that we know where the cross-reference is from. This wasn't
  # enforced, historically, so we need to tolerate nulls in existing
  # databases (hence this is an advisory check), but this should
  # pass for new databases.
  my $desc = 'All xref annotations linked to an analysis';
  my $sql  = qq/
    SELECT COUNT(*) FROM object_xref WHERE analysis_id IS NULL;
  /;
  is_rows_zero($self->dba, $sql, $desc);
}

1;
