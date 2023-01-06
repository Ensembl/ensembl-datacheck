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

package Bio::EnsEMBL::DataCheck::Checks::GeneDescriptions;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'GeneDescriptions',
  DESCRIPTION    => 'Gene descriptions are correctly formatted',
  GROUPS         => ['core', 'xref', 'xref_gene_symbol_transformer', 'xref_mapping'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['coord_system', 'gene', 'seq_region']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc_1 = 'Gene descriptions do not contain newlines or tabs';
  my $diag_1 = 'Non-printing character';
  my $sql_1  = qq/
    SELECT g.gene_id, g.stable_id FROM gene g 
    INNER JOIN seq_region sr USING (seq_region_id) 
    INNER JOIN  coord_system cs USING (coord_system_id)   
    WHERE cs.species_id = $species_id
    AND g.description REGEXP '[\n\r\t]+'
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  my $desc_2 = 'Gene descriptions have correct capitalisation of "UniProt"';
  my $diag_2 = 'Incorrect "UniProt" format';
  my $sql_2  = qq/
    SELECT g.gene_id, g.stable_id, g.description FROM gene g 
    INNER JOIN seq_region sr USING (seq_region_id) 
    INNER JOIN  coord_system cs USING (coord_system_id) 
    WHERE cs.species_id = $species_id 
    AND g.description LIKE BINARY '%Uniprot%'
  /;

  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);
}

1;
