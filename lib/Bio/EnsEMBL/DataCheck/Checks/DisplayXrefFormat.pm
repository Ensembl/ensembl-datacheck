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

package Bio::EnsEMBL::DataCheck::Checks::DisplayXrefFormat;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'DisplayXrefFormat',
  DESCRIPTION    => 'Gene names are correctly formatted',
  GROUPS         => ['core', 'xref', 'xref_gene_symbol_transformer', 'xref_mapping'],
  DB_TYPES       => ['core'],
  TABLES         => ['coord_system', 'external_db', 'gene', 'seq_region', 'xref'],
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc = "EntrezGene gene names are not numeric";
  my $sql  = qq/
    SELECT COUNT(*) FROM
      gene g INNER JOIN 
      seq_region sr USING (seq_region_id) INNER JOIN 
      coord_system cs USING (coord_system_id) INNER JOIN 
      xref x ON g.display_xref_id = x.xref_id INNER JOIN 
      external_db e ON e.external_db_id = x.external_db_id 
    WHERE
      cs.species_id = $species_id AND 
      e.db_name = 'EntrezGene' AND 
      x.display_label REGEXP '^[0-9]+\$';
  /;

  is_rows_zero($self->dba, $sql, $desc);
}

1;
