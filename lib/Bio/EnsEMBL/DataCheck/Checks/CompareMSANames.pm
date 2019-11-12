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

package Bio::EnsEMBL::DataCheck::Checks::CompareMSANames;

use warnings;
use strict;
use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareMSANames',
  DESCRIPTION    => 'The species_sets from the previous database are still present',
  GROUPS         => ['compara', 'compara_multiple_alignments'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['compara'],
  TABLES         => ['method_link', 'method_link_species_set', 'species_set_header']
};

sub tests {
  my ($self) = @_;
  
  Bio::EnsEMBL::Registry->load_all($self->registry_file);

  my $curr_dba = $self->dba;
  my $prev_dba = Bio::EnsEMBL::Compara::DBSQL::DBAdaptor->go_figure_compara_dba('compara_prev');
  my $curr_db_name = $curr_dba->dbc->dbname;
  my $prev_db_name = $prev_dba->dbc->dbname;
  my $curr_mlss_adap = $curr_dba->get_MethodLinkSpeciesSetAdaptor;
  my $prev_mlss_adap = $prev_dba->get_MethodLinkSpeciesSetAdaptor;
  my @mlss_types = qw ( PECAN EPO EPO_LOW_COVERAGE CACTUS_HAL );
  my @curr_mlsses;
  my @prev_mlsses;
  
  foreach my $mlss_type ( @mlss_types ) {
    my $curr_mlss_ids = $curr_mlss_adap->fetch_all_by_method_link_type($mlss_type);
    my $prev_mlss_ids = $prev_mlss_adap->fetch_all_by_method_link_type($mlss_type);
    push @curr_mlsses, @$curr_mlss_ids;
    push @prev_mlsses, @$prev_mlss_ids;
  }
  
  my $curr_count = scalar(@curr_mlsses);
  my $prev_count = scalar(@prev_mlsses);
  
  my $desc_1 = "$curr_db_name has no fewer mlsses than $prev_db_name";
  cmp_ok( $curr_count, '>=', $prev_count, $desc_1 );
  
  my $curr_mlss_names;
  my $prev_mlss_names;
  
  foreach my $mlss ( @prev_mlsses ) {
    push ( @{ $prev_mlss_names->{$mlss->species_set->name} }, $mlss );
  }
  foreach my $mlss ( @curr_mlsses ) {
    push ( @{ $curr_mlss_names->{$mlss->species_set->name} }, $mlss );
  }
  
  my $desc_2 = "There are no new species_sets in $curr_db_name that were not in $prev_db_name";
  cmp_ok( ( scalar keys $prev_mlss_names ), '==', ( scalar keys $curr_mlss_names ), $desc_2 );
  
  foreach my $species_set_name ( keys $prev_mlss_names ) {
    my $desc_4 = "$species_set_name is present in $curr_db_name";
    if ( exists ($curr_mlss_names->{$species_set_name}) ) {
      pass( $desc_4 );
      my $desc_3 = "There are no fewer methods for species_set <$species_set_name> in $curr_db_name than in $prev_db_name";
      cmp_ok( @{ $prev_mlss_names->{$species_set_name} }, '<=', @{ $curr_mlss_names->{$species_set_name} }, $desc_3 );
    }
    else {
      fail( $desc_4 );
    }
  }
  
  foreach my $species_set_name ( keys $curr_mlss_names ) {
    my $desc_4 = "There are no new methods for species_set <$species_set_name> in $curr_db_name than in $prev_db_name";
    my $prev_mlss_name_count = 0;
    if (exists $prev_mlss_names->{$species_set_name}) {
        $prev_mlss_name_count = $prev_mlss_names->{$species_set_name};
        cmp_ok( @{ $prev_mlss_names->{$species_set_name} }, '==', @{ $curr_mlss_names->{$species_set_name} }, $desc_4 );
    }
  }
}

1;

