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
  GROUPS         => ['compara', 'compara_protein_trees'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['CAFE_gene_family', 'gene_tree_root']
};

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;
  
  my $sql = qq/
    SELECT member_type, COUNT(*) 
      FROM gene_tree_root gtr 
        JOIN CAFE_gene_family cgf 
          ON(gtr.root_id=cgf.gene_tree_root_id) 
    WHERE gtr.tree_type = 'tree' 
      GROUP BY gtr.member_type
  /;
  
  my $desc = "There is data for ncRNA and protein gain/loss trees in the gene_tree_root and CAFE_gene_family tables";
  cmp_rows($dbc, $sql, "==", 2, $desc);
}

1;

