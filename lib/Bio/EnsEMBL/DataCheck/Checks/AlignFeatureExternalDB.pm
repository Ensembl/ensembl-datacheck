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

package Bio::EnsEMBL::DataCheck::Checks::AlignFeatureExternalDB;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'AlignFeatureExternalDB',
  DESCRIPTION    => 'All alignment features are linked to an external DB',
  GROUPS         => ['annotation', 'core', 'corelike'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['cdna', 'core', 'otherfeatures', 'rnaseq'],
  TABLES         => ['coord_system', 'dna_align_feature', 'protein_align_feature', 'seq_region']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  foreach my $table ('dna_align_feature', 'protein_align_feature') {
    my $desc = "All $table rows have an external_db_id";
    my $sql  = qq/
      SELECT COUNT(*) FROM
        $table INNER JOIN
        seq_region USING (seq_region_id) INNER JOIN
        coord_system USING (coord_system_id)
      WHERE
        $table.external_db_id IS NULL OR external_db_id = 0 AND
        coord_system.species_id = $species_id
    /;
    is_rows_zero($self->dba, $sql, $desc);
  }
}

1;
