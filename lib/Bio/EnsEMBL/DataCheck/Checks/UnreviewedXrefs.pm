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

package Bio::EnsEMBL::DataCheck::Checks::UnreviewedXrefs;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'UnreviewedXrefs',
  DESCRIPTION    => 'Uniprot xrefs do not have Unreviewed as their primary DB accession',
  GROUPS         => ['core', 'xref', 'xref_mapping'],
  DB_TYPES       => ['core'],
  TABLES         => ['xref','external_db'],
  PER_DB         => 1
};

sub tests {
  my ($self) = @_;
  my $desc = "Uniprot xrefs do not have Unreviewed as their primary DB accession";
  my $sql  = qq/
    SELECT COUNT(*) FROM 
      xref x, external_db e
    WHERE
      e.external_db_id=x.external_db_id AND
      e.db_name LIKE 'UniProt%' AND
      x.dbprimary_acc='Unreviewed'
  /;
  is_rows_zero($self->dba, $sql, $desc);
}
1;
