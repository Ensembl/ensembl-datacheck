=head1 LICENSE

Copyright [2018-2025] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::HighConfidence;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'HighConfidence',
  DESCRIPTION    => 'Checks that the HighConfidenceOrthologs pipeline has been run',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_gene_tree_pipelines'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['homology']
};

sub skip_tests {
  my ($self) = @_;

  my $division = $self->dba->get_division();
  if ( $division =~ /fungi/ ) {
    return( 1, "HighConfidence data are not generated for $division" );
  }

  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my $mlss = $mlss_adap->fetch_all_by_method_link_type('ENSEMBL_ORTHOLOGUES');
  my $db_name = $self->dba->dbc->dbname;

  if ( scalar(@$mlss) == 0 ) {
    return( 1, "There are no ENSEMBL_ORTHOLOGUES MLSS in $db_name" );
  }
}

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;

  my $sql = q/
    SELECT COUNT(*) 
      FROM homology 
    WHERE is_high_confidence IS NULL
      AND description LIKE "ortholog%"
  /;

  my $desc = "Homologies have been annotated with a confidence value";

  is_rows_zero($dbc, $sql, $desc);
}

1;

