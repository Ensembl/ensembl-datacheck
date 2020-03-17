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

package Bio::EnsEMBL::DataCheck::Checks::SharedDisplayXref;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'SharedDisplayXref',
  DESCRIPTION    => 'Protein coding gene/transcript display xrefs are not shared between species inside a collection. This can lead to species-specific synonyms being applied to the wrong species',
  GROUPS         => ['xref', 'core'],
  DB_TYPES       => ['core'],
  TABLES         => ['gene', 'transcript', 'seq_region', 'coord_system','xref'],
  PER_DB         => 1,
};

sub skip_tests {
  my ($self) = @_;

  if (! $self->dba->is_multispecies) {
    return (1, 'Only applies to collection databases.');
  }
}

sub tests {
  my ($self) = @_;

  $self->shared_display_xref($self->dba,'gene');
  $self->shared_display_xref($self->dba,'transcript');
}

sub shared_display_xref {
  my ($self, $dba, $table) = @_;

  my $desc = "No protein-coding $table display xrefs shared between species";
  my $diag = "Xref accession";
  my $sql  = qq/
    SELECT x.dbprimary_acc FROM
      xref x JOIN 
      $table tb ON tb.display_xref_id=x.xref_id JOIN
      seq_region sr USING (seq_region_id) JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      tb.biotype='protein_coding'
    GROUP BY x.dbprimary_acc
    HAVING COUNT(DISTINCT (cs.species_id)) > 1
  /;

  is_rows_zero($dba, $sql, $desc, $diag);
}

1;
