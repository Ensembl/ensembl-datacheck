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
  GROUPS         => ['xref', 'core'],
  DB_TYPES       => ['core'],
  TABLES         => ['coord_system', 'external_db', 'object_xref', 'ontology_xref', 'seq_region', 'transcript', 'xref']
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;

  my $desc = "All GO xrefs have an evidence";
  my $sql  = qq/
    SELECT COUNT(*) FROM
      transcript t INNER JOIN
      object_xref ox ON t.transcript_id = ox.ensembl_id INNER JOIN
      xref x using (xref_id) INNER JOIN
      external_db e using (external_db_id) LEFT OUTER JOIN
      ontology_xref oox using (object_xref_id) INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id)
    WHERE
      ox.ensembl_object_type = 'Transcript' AND
      e.db_name = 'GO' AND
      oox.object_xref_id IS NULL AND
      species_id = $species_id
    /;
    is_rows_zero($self->dba, $sql, $desc);
}

1;
