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

package Bio::EnsEMBL::DataCheck::Checks::UniProtDisplayXref;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'UniProtDisplayXref',
  DESCRIPTION    => 'Gene display xrefs are only attached to UniProtKB Gene Names (Uniprot_gn)',
  GROUPS         => ['core', 'xref', 'xref_gene_symbol_transformer', 'xref_mapping'],
  DB_TYPES       => ['core'],
  TABLES         => ['gene', 'xref', 'external_db','seq_region','coord_system'],
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;
  my $desc = 'No Genes display_xref are attached to Uniprot/*, instead of UniProtKB Gene Name (Uniprot_gn)';
  my $diag = 'Gene Stable ID';
  my $sql  = qq/
    SELECT g.stable_id FROM
      gene g INNER JOIN
      xref x INNER JOIN
      external_db d USING (external_db_id) INNER JOIN 
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE 
      g.display_xref_id = x.xref_id AND
      d.db_name IN ('Uniprot\/SPTREMBL','Uniprot\/SPTREMBL_predicted','Uniprot\/SWISSPROT','Uniprot\/SWISSPROT_predicted') AND
      cs.species_id = $species_id
  /;
   
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;
