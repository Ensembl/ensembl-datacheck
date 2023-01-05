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

package Bio::EnsEMBL::DataCheck::Checks::CheckConstrainedElementTable;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::Utils::SqlHelper;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckConstrainedElementTable',
  DESCRIPTION    => 'Each row should show a one-to-many relationship',
  GROUPS         => ['compara', 'compara_genome_alignments'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['constrained_elements', 'method_link_species_set']
};

sub skip_tests {
  my ($self) = @_;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my $mlss = $mlss_adap->fetch_all_by_method_link_type('GERP_CONSTRAINED_ELEMENT');
  my $db_name = $self->dba->dbc->dbname;

  if ( scalar(@$mlss) == 0 ) {
    return( 1, "There are no GERP_CONSTRAINED_ELEMENT MLSS in $db_name" );
  }
}

sub tests {
  my ($self) = @_;
  my $dba = $self->dba;
  my $helper = $dba->dbc->sql_helper;

  my $desc = "All the rows in constrained_element have a one-to-many relationship for constrained_element_id";
  
  is_one_to_many($dba->dbc, "constrained_element", "constrained_element_id", $desc);

  my $mlsss = $self->dba->get_MethodLinkSpeciesSetAdaptor->fetch_all_by_method_link_type('GERP_CONSTRAINED_ELEMENT');

  my $expected_ce_count;

  foreach my $mlss ( @$mlsss ) {

    my $mlss_id   = $mlss->dbID;
    my $mlss_name = $mlss->name;

    my $sql = qq/
      SELECT COUNT(*)
        FROM constrained_element
      WHERE method_link_species_set_id = $mlss_id
    /;

    $expected_ce_count += $helper->execute_single_result(-SQL => $sql);

    my $desc_1 = "The constrained elements for $mlss_id ($mlss_name) are present as expected";
    is_rows_nonzero($dba, $sql, $desc_1);
  }

  my $desc_2 = "All the constrained elements with corresponding method_link_species_sets are expected";
  my $row_count_sql = "SELECT COUNT(*) FROM constrained_element";
  is_rows($dba, $row_count_sql, $expected_ce_count, $desc_2);

}

1;

