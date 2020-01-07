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

package Bio::EnsEMBL::DataCheck::Checks::GOXrefEvidence;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;


extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'GOXrefEvidence',
  DESCRIPTION => 'All GO xrefs have an evidence',
  GROUPS         => ['xref'],
  DB_TYPES       => ['core'],
  TABLES         => ['object_xref','xref', 'external_db', 'ontology_xref']
};

sub tests {
  my ($self) = @_;
  my $desc = "All GO xrefs have an evidence";
  my $sql  = qq/
      SELECT COUNT(*) FROM
        object_xref ox JOIN
        xref x using (xref_id) JOIN
			  external_db e using (external_db_id) LEFT JOIN
			  ontology_xref oox using (object_xref_id)
      WHERE
        e.db_name='GO' AND 
        oox.object_xref_id is null
    /;
    is_rows_zero($self->dba, $sql, $desc);
}

1;
