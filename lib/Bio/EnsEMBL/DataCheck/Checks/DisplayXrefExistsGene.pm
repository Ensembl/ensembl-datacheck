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

sub skip_tests {
  my ($self) = @_;

  # Teams responsible for ensuring display xrefs exist
  my @responsible_teams = ('Genebuild');

  my $mca = $self->dba->get_adaptor("MetaContainer");
  my $teams = $mca->list_value_by_key('genebuild.team_responsible');

  if (!defined $teams) {
    return (1, 'genebuild.team_responsible not defined, skipping the test');
  }

  my %lookup = map { $_ => 1 } @$teams;
  if (!grep { exists $lookup{$_} } @responsible_teams) {
    return (1, "genebuild.team_responsible does not match responsible teams (" . join(', ', @responsible_teams) . "), skipping the test");
  }

  return 0;
}

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc = "Genes have names set via display_xref_id";
  my $sql  = qq/
    SELECT COUNT(*) FROM gene t
      INNER JOIN seq_region sr USING (seq_region_id)
      INNER JOIN coord_system cs USING (coord_system_id)
    WHERE cs.species_id = $species_id
      AND t.display_xref_id IS NOT NULL
  /;

  is_rows_nonzero($self->dba, $sql, $desc);
}

1;
