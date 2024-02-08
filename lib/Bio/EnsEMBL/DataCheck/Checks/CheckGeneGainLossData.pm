=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CheckGeneGainLossData;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckGeneGainLossData',
  DESCRIPTION    => 'ncRNA and protein trees must have gene Gain/Loss trees',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_gene_tree_pipelines'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['CAFE_gene_family', 'gene_tree_root']
};

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;

  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my @methods = qw (PROTEIN_TREES NC_TREES);

  my @mlsses;
  foreach my $method ( @methods ) {
    my $mlss = $mlss_adap->fetch_all_by_method_link_type($method);
    push @mlsses, @$mlss;
  }

  my $mlsses_with_cafe = 0;
  foreach my $mlss ( @mlsses ) {
    next unless $mlss->get_value_for_tag('has_cafe');
    $mlsses_with_cafe++;
    my $mlss_id = $mlss->dbID;
    my $sql = qq/
    SELECT member_type, COUNT(*) 
      FROM gene_tree_root gtr 
        LEFT JOIN CAFE_gene_family cgf
          ON(gtr.root_id=cgf.gene_tree_root_id) 
    WHERE gtr.tree_type = 'tree'
      AND gtr.method_link_species_set_id = $mlss_id
      GROUP BY gtr.member_type
      HAVING COUNT(cgf.gene_tree_root_id) = 0
    /;

    my $mlss_name = $mlss->name;
    my $desc = "All member types have gain/loss trees for $mlss_name";
    is_rows_zero($self->dba, $sql, $desc);
  }

  unless ($mlsses_with_cafe) {
    plan skip_all => "No MLSSs with gain/loss data in this database";
  }
}

1;
