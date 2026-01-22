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

package Bio::EnsEMBL::DataCheck::Checks::DisplayXrefExistsGene;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'DisplayXrefExistsGene',
  DESCRIPTION    => 'At least one gene name exists',
  GROUPS         => ['rapid_release'],
  DATACHECK_TYPE => 'critical',
  TABLES         => ['coord_system', 'gene', 'seq_region', 'xref'],
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  # Teams responsible for ensuring display xrefs exist
  my @responsible_teams = ('Genebuild');
  my $teams_list = join("', '", @responsible_teams);

  my $desc = "Genes have names set via display_xref_id";
  # Use CASE to return 1 (pass) for teams not responsible for display xrefs,
  # but actual count for responsible teams
  my $sql  = qq/
    SELECT COUNT(*) FROM (
      SELECT CASE
        WHEN EXISTS (
          SELECT 1 FROM meta
          WHERE meta_key = 'genebuild.team_responsible'
            AND meta_value IN ('$teams_list')
            AND (species_id IS NULL OR species_id = $species_id)
        )
        THEN (
          SELECT COUNT(*) FROM gene t
            JOIN seq_region sr USING (seq_region_id)
            JOIN coord_system cs USING (coord_system_id)
          WHERE cs.species_id = $species_id
            AND t.display_xref_id IS NOT NULL
        )
        ELSE 1
      END AS count_result
    ) AS subquery
    WHERE count_result > 0
  /;

  is_rows_nonzero($self->dba, $sql, $desc);
}

1;
