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

package Bio::EnsEMBL::DataCheck::Checks::MLSSTagHomology;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::Compara;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MLSSTagHomology',
  DESCRIPTION => 'Homologies have appropriate tags',
  GROUPS      => ['compara', 'compara_gene_trees'],
  DB_TYPES    => ['compara'],
  TABLES      => ['method_link', 'method_link_species_set', 'method_link_species_set_tag']
};

sub skip_tests {
  my ($self) = @_;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my @methods = qw( PROTEIN_TREES NC_TREES );
  my $db_name = $self->dba->dbc->dbname;
  
  my @mlsses;
  foreach my $method ( @methods ) {
    my $mlss = $mlss_adap->fetch_all_by_method_link_type($method);
    push @mlsses, @$mlss;
  }
  
  if ( scalar(@mlsses) == 0 ) {
    return( 1, "There are no gene trees in $db_name" );
  }
}

sub tests {
  my ($self) = @_;

  my $orthologue_tags = [
    'n_protein_many-to-many_groups',
    'n_protein_many-to-many_pairs',
    'n_protein_many-to-one_groups',
    'n_protein_many-to-one_pairs',
    'n_protein_one-to-many_groups',
    'n_protein_one-to-many_pairs',
    'n_protein_one-to-one_groups',
    'n_protein_one-to-one_pairs'
  ];
  my $paralogue_tags = [
    'n_protein_within_species_paralog_genes',
    'n_protein_within_species_paralog_groups',
    'n_protein_within_species_paralog_pairs',
    'avg_protein_within_species_paralog_perc_id'
  ];

  has_tags($self->dba, 'ENSEMBL_ORTHOLOGUES', $orthologue_tags);
  has_tags($self->dba, 'ENSEMBL_PARALOGUES', $paralogue_tags);
}

1;
