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
  GROUPS      => ['xref', 'xref_gene_symbol_transformer', 'core'],
  DB_TYPES    => ['core'],
  TABLES      => ['object_xref', 'ontology_xref', 'xref'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  # We deliberately do not join the external_db table and filter on
  # db_name = 'GO', because there is no (usable) index on that field,
  # and the query takes an exceptionally long time on collection dbs,
  # which have millions of xref rows.
  my $desc = "All GO xrefs have an evidence";
  my $sql  = qq/
    SELECT COUNT(*) FROM
      object_xref ox INNER JOIN
      xref x using (xref_id) LEFT OUTER JOIN
      ontology_xref oox using (object_xref_id)
    WHERE
      x.dbprimary_acc = 'GO:%' AND
      oox.object_xref_id IS NULL
    /;
    is_rows_zero($self->dba, $sql, $desc);
}

1;
