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

package Bio::EnsEMBL::DataCheck::Checks::CheckGenomicAlignTreeTable;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckGenomicAlignTreeTable',
  DESCRIPTION    => 'Check the consistency and validity of genomic_align_tree',
  GROUPS         => ['compara', 'compara_genome_alignments'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['genomic_align_tree', 'method_link_species_set']
};

sub skip_tests {
    my ($self) = @_;
    my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
    my @methods = qw( EPO EPO_EXTENDED );
    my $db_name = $self->dba->dbc->dbname;
    
    my @mlsses;
    foreach my $method ( @methods ) {
      my $mlss = $mlss_adap->fetch_all_by_method_link_type($method);
      push @mlsses, @$mlss;
    }

    if ( scalar(@mlsses) == 0 ) {
      return( 1, "There are no multiple alignments in $db_name" );
    }

}

sub tests {
  my ($self) = @_;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my @methods = qw( EPO EPO_EXTENDED );
  my $db_name = $self->dba->dbc->dbname;
  my $dbc = $self->dba->dbc;
  my $helper = $dbc->sql_helper;
  my @mlsses;

  foreach my $method ( @methods ) {
    my $mlss = $mlss_adap->fetch_all_by_method_link_type($method);
    push @mlsses, @$mlss;
  }

  foreach my $mlss ( @mlsses ) {
    my $mlss_id = $mlss->dbID;
    my $mlss_name = $mlss->name;
    my $condition = "FLOOR(node_id/10000000000) = $mlss_id";
    my @columns = qw( parent_id left_node_id right_node_id );
    foreach my $column ( @columns ) {
      my $sql_1 = qq/
        SELECT COUNT(*) 
          FROM genomic_align_tree
        WHERE $condition
          AND $column IS NOT NULL
      /;
      my $desc_1 = "$column of genomic_align_tree is sometimes populated for $mlss_id ($mlss_name)";
      is_rows_nonzero( $dbc, $sql_1, $desc_1 );
    }

    my $sql_2 = qq/
      SELECT COUNT(*)
        FROM genomic_align_tree
      WHERE $condition 
    /;
    
    my $sql_3 = qq/
      SELECT COUNT(*)
        FROM genomic_align_tree
      WHERE $condition
        AND distance_to_parent > 1
    /;
    
    my $desc_3 = "Less than 1% of entries have a distance_to_parent > 1 for $mlss_id ($mlss_name)";

    my $expected_count = $helper->execute_single_result( -SQL => $sql_2 );
    my $got_count = $helper->execute_single_result( -SQL => $sql_3 );
    cmp_ok( $got_count, '<=', $expected_count * 0.01, $desc_3 )

  }

}

1;

