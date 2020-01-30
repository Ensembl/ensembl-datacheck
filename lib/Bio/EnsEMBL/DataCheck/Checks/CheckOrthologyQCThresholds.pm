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

package Bio::EnsEMBL::DataCheck::Checks::CheckOrthologyQCThresholds;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckOrthologyQCThresholds',
  DESCRIPTION    => 'Check that some wga_coverage and goc_score thresholds have been populated',
  GROUPS         => ['compara', 'compara_protein_trees'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['method_link_species_set_attr']
};

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;

  my $goc_sql = qq/
    SELECT COUNT(*)
      FROM method_link_species_set_attr
    WHERE goc_quality_threshold IS NOT NULL
  /;
  my $has_goc_scores = sql_count($self->dba, 'SELECT 1 FROM homology WHERE goc_score IS NOT NULL LIMIT 1');
  my $desc_goc = 'The method_link_species_set_attr has ' . ($has_goc_scores ? 'some' : 'no') . ' goc_quality_thresholds';
  cmp_rows($self->dba, $goc_sql, $has_goc_scores ? '>' : '==', 0, $desc_goc);

  my $wga_sql = qq/
    SELECT COUNT(*)
      FROM method_link_species_set_attr
    WHERE wga_quality_threshold IS NOT NULL
  /;
  my $has_wga_scores = sql_count($self->dba, 'SELECT 1 FROM homology WHERE wga_coverage IS NOT NULL LIMIT 1');
  my $desc_wga = 'The method_link_species_set_attr has ' . ($has_wga_scores ? 'some' : 'no') . ' wga_quality_thresholds';
  cmp_rows($self->dba, $wga_sql, $has_wga_scores ? '>' : '==', 0, $desc_wga);
}

1;

