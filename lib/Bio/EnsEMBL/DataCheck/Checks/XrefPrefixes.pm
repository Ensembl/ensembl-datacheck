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

package Bio::EnsEMBL::DataCheck::Checks::XrefPrefixes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'XrefPrefixes',
  DESCRIPTION    => 'Check that xrefs have the correct prefix for their dbprimary_acc',
  GROUPS         => ['core', 'xref', 'xref_gene_symbol_transformer', 'xref_mapping'],
  DB_TYPES       => ['core'],
  TABLES         => ['xref', 'external_db'],
  PER_DB         => 1
};

sub tests {
  my ($self) = @_;
  my $prefixes = {
  'BARLEX' => '^HORVU',
  'CCDS' => '^CCDS',
  'CL' => '^CL:',
  'ChEBI' => '^CHEBI:',
  'ChEMBL' => '^ChEMBL',
  'EcoGene' => '^EG',
  'FYPO_EXT' => '^FYPO_EXT:',
  'FlyBaseName_gene' => '^FB',
  'FlyBaseName_transcript' => '^FB',
  'FlyBaseName_translation' => '^FB',
  'GO' => '^GO:',
  'GO_REF' => '^GO_REF:',
  'HGNC' => '^HGNC:',
  'Interpro' => '^IPR',
  'MGI' => '^MGI:',
  'MaizeGDB' => '^Zm',
  'MetaCyc' => '^PWY',
  'PATO' => '^PATO:',
  'PHI' => '^PHI:',
  'PR' => '^PR:',
  'PUBMED_POMBASE' => '^PMPB:',
  'Plant_Reactome_Pathway' => '^R-',
  'Plant_Reactome_Reaction' => '^R-',
  'RFAM' => '^RF',
  'RNAcentral' => '^URS',
  'RefSeq_mRNA' => '^NM_|^XM_',
  'RefSeq_mRNA_predicted' => '^XM_',
  'RefSeq_ncRNA' => '^NR_|^XR_',
  'RefSeq_ncRNA_predicted' => '^XR_',
  'RefSeq_peptide' => '^NP|^YP|^AP|^XP',
  'RefSeq_peptide_predicted' => '^XP',
  'SGD' => '^S',
  'SGD_GENE' => '^S',
  'UniParc' => '^UPI',
  'UniPathway' => '^UPA',
  'VGNC' => '^VGNC:',
  'WHEATEXP_GENE' => '^Traes',
  'WHEATEXP_TRANS' => '^Traes',
  'Xenbase' => '^XB',
  'ZFIND_ID' => '^ZDB',
  'cint_aniseed_v1' => '^ci',
  'dictyBase' => '^DDB',
  'flybase_gene_id' => '^FB',
  'flybase_transcript_id' => '^FB',
  'flybase_translation_id' => '^FB',
  'goslim_goa' => '^GO:',
  'miRBase' => '^MI',
  'wormbase_gene' => '^WB',
  'wormbase_gseqname' => '^WB',
  'wormbase_locus' => '^WB'
  };
  while (my ($source_name, $pattern) = each(%$prefixes)) {
    $self->xref_prefixes_check($source_name, $pattern,"All dbprimary accessions for xref $source_name are prefixed with the correct pattern: $pattern");
  }
}

sub xref_prefixes_check {
  my ($self,$source_name,$pattern,$desc) = @_;    
  my $sql  = qq/
      SELECT dbprimary_acc FROM xref x, external_db e
      WHERE
        x.external_db_id = e.external_db_id AND
        e.db_name = '$source_name' AND
        x.dbprimary_acc NOT REGEXP '$pattern'
    /;
  is_rows_zero($self->dba, $sql, $desc);
}

1;
