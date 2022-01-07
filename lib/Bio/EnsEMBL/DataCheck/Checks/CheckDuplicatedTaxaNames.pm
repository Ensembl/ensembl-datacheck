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

package Bio::EnsEMBL::DataCheck::Checks::CheckDuplicatedTaxaNames;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckDuplicatedTaxaNames',
  DESCRIPTION    => 'Check that the ncbi_taxa_name contains only unique rows',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_genome_alignments', 'compara_master', 'compara_syntenies', 'compara_references', 'compara_homology_annotation', 'compara_blastocyst'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['ncbi_taxa_name']
};

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;
  
  my $sql = qq/
    SELECT taxon_id, name, name_class, count(*) 
      FROM ncbi_taxa_name 
        GROUP BY taxon_id, name, name_class 
      HAVING count(*) > 1;
  /;
  
  my $desc = "All the rows in ncbi_taxa_name are unique";
  
  is_rows_zero($dbc, $sql, $desc);
  
}

1;

