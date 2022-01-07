=head1 LICENSE

Copyright [2018-2022] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CheckHomologyMLSS;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::Utils::SqlHelper;
use Data::Dumper;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckHomologyMLSS',
  DESCRIPTION    => 'The expected number of homologys MLSSs are present',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_homology_annotation', 'compara_blastocyst'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['method_link_species_set', 'homology']
};

sub tests {
  my ($self) = @_;
  my $dba    = $self->dba;
  my $helper = $dba->dbc->sql_helper;
  my @method_links = qw(ENSEMBL_ORTHOLOGUES ENSEMBL_PARALOGUES ENSEMBL_HOMOEOLOGUES ENSEMBL_PROJECTIONS);
  if ($dba->dbc->dbname !~ /ensembl_compara|protein_trees|ncrna_trees/) {
    @method_links = qw(ENSEMBL_HOMOLOGUES);
  }

  my $expected_homology_count;

  foreach my $method_link_type ( @method_links ) {
    my $mlsss = $self->dba->get_MethodLinkSpeciesSetAdaptor->fetch_all_by_method_link_type($method_link_type);
    # Only check from the method_links that have mlsss there are other datachecks to check if mlsss are correct
    next if scalar(@$mlsss) == 0;

    foreach my $mlss ( @$mlsss ) {

      my $mlss_id   = $mlss->dbID;
      my $mlss_name = $mlss->name;

      my $sql = qq/
        SELECT COUNT(*)
          FROM homology
        WHERE method_link_species_set_id = $mlss_id
      /;

      $expected_homology_count += $helper->execute_single_result(-SQL => $sql);

      my $desc_1 = "The homology for $mlss_id ($mlss_name) has rows as expected";
      is_rows_nonzero($dba, $sql, $desc_1);
    }
  }

  # Check that all the homologies correspond to a method_link_species_set that should have homology
  my $desc_2 = "All the homology rows with corresponding method_link_species_sets are expected";
  my $row_count_sql = "SELECT COUNT(*) FROM homology";
  # Rapid release homologies only have ENSEMBL_HOMOLOGUES and may be incompatible with some API methods
  # in the per-species compara database
  if ( !defined $expected_homology_count and scalar(@method_links) == 1 ) {
    my $method_link = $method_links[0];
    my $method_link_id = $self->dba->get_MethodAdaptor->fetch_by_type($method_link)->dbID;
    my $mlss_count_sql = qq/
      SELECT COUNT(DISTINCT method_link_species_set_id)
        FROM homology
    /;
    my $exp_count = $helper->execute_single_result(-SQL => $mlss_count_sql);
    my $homology_count_sql = qq/
      SELECT COUNT(method_link_species_set_id)
        FROM method_link_species_set
      WHERE method_link_id = $method_link_id
    /;
    is_rows($dba, $homology_count_sql, $exp_count, $desc_2);
  }
  else {
    is_rows($dba, $row_count_sql, $expected_homology_count, $desc_2);
  }
}

1;
