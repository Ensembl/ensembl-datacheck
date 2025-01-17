=head1 LICENSE

Copyright [2018-2025] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::NCBIGeneLabels;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'NCBIGeneLabels',
  DESCRIPTION    => 'NCBI genes have display xrefs',
  GROUPS         => ['corelike', 'xref', 'xref_gene_symbol_transformer'],
  DB_TYPES       => ['otherfeatures'],
  TABLES         => ['external_db', 'gene', 'object_xref', 'transcript', 'xref'],
};

sub tests {
  my ($self) = @_;

  # If a RefSeq geneset has been loaded with arbitrary
  # generic IDs as stable_ids, the display_xref must be set
  # in order for the browser to show the appropriate accession.
  my $desc_1 = 'NCBI genes have accession as either stable_id or display_xref';
  my $sql_1  = qq/
    SELECT stable_id FROM
      gene INNER JOIN
      object_xref ON gene_id = ensembl_id INNER JOIN
      xref USING (xref_id) INNER JOIN
      external_db USING (external_db_id) INNER JOIN
      analysis ON gene.analysis_id = analysis.analysis_id
    WHERE
      ensembl_object_type = 'Gene' AND
      db_name = 'EntrezGene' AND
      stable_id NOT IN (dbprimary_acc, display_label) AND
      display_xref_id IS NULL AND
      logic_name = 'refseq_import'
    /;
  is_rows_zero($self->dba, $sql_1, $desc_1);

  my $desc_2 = 'NCBI transcripts have accession as either stable_id or display_xref';
  my $sql_2  = qq/
    SELECT stable_id FROM
      transcript INNER JOIN
      object_xref ON gene_id = ensembl_id INNER JOIN
      xref USING (xref_id) INNER JOIN
      external_db USING (external_db_id) INNER JOIN
      analysis ON transcript.analysis_id = analysis.analysis_id
    WHERE
      ensembl_object_type = 'Transcript' AND
      db_name = 'EntrezGene' AND
      stable_id NOT IN (dbprimary_acc, display_label) AND
      display_xref_id IS NULL AND
      logic_name = 'refseq_import'
    /;
  is_rows_zero($self->dba, $sql_2, $desc_2);
}

1;
