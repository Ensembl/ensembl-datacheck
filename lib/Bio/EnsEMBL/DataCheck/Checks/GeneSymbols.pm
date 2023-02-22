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

package Bio::EnsEMBL::DataCheck::Checks::GeneSymbols;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'GeneSymbols',
  DESCRIPTION    => 'Gene Symbols need to be assigned for all Ensembl annotations, via the Gene Symbol Transformer classification',
  GROUPS         => ['rapid_release'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['meta']
};

sub tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");

 SKIP: {
     my $method = $mca->single_value_by_key('genebuild.method');
     if($method ne 'anno' && $method ne 'full_genebuild') {
         skip "Gene Symbols not mandatory for non-Genebuild annotations", 1;
     }

     my $desc = 'Gene Symbol Transformer has been run';
     my $sql  = qq/
      SELECT COUNT(*) FROM
        analysis
      WHERE
        logic_name LIKE 'gene_symbol_classifier'
    /;
    is_rows_nonzero($self->dba, $sql, $desc);
  }

}
1;
