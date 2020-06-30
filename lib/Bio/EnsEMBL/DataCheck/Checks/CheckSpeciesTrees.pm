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

package Bio::EnsEMBL::DataCheck::Checks::CheckSpeciesTrees;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::Utils::SqlHelper;
use Data::Dumper;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckSpeciesTrees',
  DESCRIPTION    => 'The expected number of species trees have been merged',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_genome_alignments'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['method_link_species_set', 'species_set', 'species_tree_root']
};

sub tests {
  my ($self) = @_;
  my $dba    = $self->dba;
  my $helper = $dba->dbc->sql_helper;
  my @method_links = qw(CACTUS_HAL EPO EPO_EXTENDED PECAN PROTEIN_TREES NC_TREES SPECIES_TREE);

  my $expected_tree_count;

  foreach my $method_link_type ( @method_links ) {

    my $mlsss = $self->dba->get_MethodLinkSpeciesSetAdaptor->fetch_all_by_method_link_type($method_link_type);
    # Only check from the method_links that have mlsss there are other datachecks to check if mlsss are correct
    next if scalar(@$mlsss) == 0;

    foreach my $mlss ( @$mlsss ) {

      my $mlss_id   = $mlss->dbID;
      my $mlss_name = $mlss->name;

      my $sql = qq/
        SELECT COUNT(*)
          FROM species_tree_root
        WHERE method_link_species_set_id = $mlss_id
      /;

      $expected_tree_count += $helper->execute_single_result(-SQL => $sql);

      my $desc_1 = "The species tree for $mlss_id ($mlss_name) is present as expected";
      is_rows_nonzero($dba, $sql, $desc_1);
    }
  }

  # Check that all the species_trees correspond to a method_link_species_set that should have a species tree
  my $desc_2 = "All the species_trees with corresponding method_link_species_sets are expected";
  my $row_count_sql = "SELECT COUNT(*) FROM species_tree_root";
  cmp_rows($dba, $row_count_sql, "==", $expected_tree_count, $desc_2);

  my $species_tree_root_constraint = q/
    method_link_id IN (
      SELECT method_link_id FROM method_link
      WHERE
        method_link_id < 100 AND
        (class LIKE 'GenomicAlignTree%' OR class LIKE '%multiple_alignment')
    )
  /;
  fk($dba, 'species_tree_root', 'method_link_species_set_id', 'method_link_species_set', 'method_link_species_set_id', $species_tree_root_constraint);
}

1;

