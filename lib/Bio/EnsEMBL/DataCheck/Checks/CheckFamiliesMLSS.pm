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

package Bio::EnsEMBL::DataCheck::Checks::CheckFamiliesMLSS;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::Utils::SqlHelper;
use Data::Dumper;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckFamiliesMLSS',
  DESCRIPTION    => 'The expected number of families MLSSs are present',
  GROUPS         => ['compara', 'compara_gene_trees'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['method_link_species_set', 'family']
};

sub skip_tests {
  my ($self) = @_;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my $mlss = $mlss_adap->fetch_all_by_method_link_type('FAMILY');
  my $db_name = $self->dba->dbc->dbname;

  if ( scalar @$mlss == 0 ) {
    return( 1, "There are no family MLSS in $db_name" );
  }
}

sub tests {
  my ($self) = @_;
  my $dba    = $self->dba;
  my $helper = $dba->dbc->sql_helper;

  my $expected_family_count;

  my $mlsss = $self->dba->get_MethodLinkSpeciesSetAdaptor->fetch_all_by_method_link_type('FAMILY');

  foreach my $mlss ( @$mlsss ) {

    my $mlss_id   = $mlss->dbID;
    my $mlss_name = $mlss->name;

    my $sql = qq/
      SELECT COUNT(*)
        FROM family
      WHERE method_link_species_set_id = $mlss_id
    /;

    $expected_family_count += $helper->execute_single_result(-SQL => $sql);

    my $desc_1 = "The family for $mlss_id ($mlss_name) has rows as expected";
    is_rows_nonzero($dba, $sql, $desc_1);
  }

  # Check that all the families correspond to a method_link_species_set that should have families
  my $desc_2 = "All the family rows with corresponding method_link_species_sets are expected";
  my $row_count_sql = "SELECT COUNT(*) FROM family";
  is_rows($dba, $row_count_sql, $expected_family_count, $desc_2);
}

1;
