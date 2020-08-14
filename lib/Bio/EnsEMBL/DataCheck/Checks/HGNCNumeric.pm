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

package Bio::EnsEMBL::DataCheck::Checks::HGNCNumeric;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'HGNCNumeric',
  DESCRIPTION => 'HGNC xrefs do not have the accession as the display_label',
  GROUPS      => ['core', 'xref'],
  TABLES      => ['external_db', 'object_xref', 'xref'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  my $desc_1 = "HGNC xrefs do not have the accession as the display_label";
  my $sql_1  = qq/
    SELECT COUNT(*) FROM
      object_xref ox INNER JOIN
      xref x USING (xref_id) INNER JOIN
      external_db e USING (external_db_id)
    WHERE
      e.db_name = 'HGNC' AND
      x.dbprimary_acc = x.display_label
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);
}

1;
