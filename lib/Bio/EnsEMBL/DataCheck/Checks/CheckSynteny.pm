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

package Bio::EnsEMBL::DataCheck::Checks::CheckSynteny;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckSynteny',
  DESCRIPTION    => 'Every synteny_region_id should be seen more than once and correspond to an mlss',
  GROUPS         => ['compara', 'compara_syntenies'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['dnafrag', 'dnafrag_region', 'synteny_region']
};

sub skip_tests {
  my ($self) = @_;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my $mlss = $mlss_adap->fetch_all_by_method_link_type('SYNTENY');
  my $db_name = $self->dba->dbc->dbname;

  if ( scalar(@$mlss) == 0 ) {
    return( 1, "There are no SYNTENY MLSS in $db_name" );
  }
}

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;

  my @tables = qw (dnafrag dnafrag_region synteny_region);

  foreach my $table ( @tables ) {
    my $sql_1 = qq/
      SELECT COUNT(*) 
        FROM $table
    /;
    my $desc_1 = "$table is populated";
    is_rows_nonzero($dbc, $sql_1, $desc_1);
  }

  my $desc_2 = "All synteny_region_ids have been seen more than once";
  is_one_to_many( $dbc, "dnafrag_region", "synteny_region_id", $desc_2 );

  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my $mlsss     = $mlss_adap->fetch_all_by_method_link_type('SYNTENY');

  foreach my $mlss ( @$mlsss ) {

    my $mlss_id   = $mlss->dbID;
    my $mlss_name = $mlss->name;

    my $sql = qq/
      SELECT COUNT(*)
        FROM synteny_region
      WHERE method_link_species_set_id = $mlss_id
    /;

    my $desc_3 = "The syntenies for $mlss_id ($mlss_name) are present as expected";
    is_rows_nonzero($dbc, $sql, $desc_3);
  }
}

1;

