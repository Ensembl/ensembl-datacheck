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

package Bio::EnsEMBL::DataCheck::Checks::TranscriptSupport;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'TranscriptSupport',
  DESCRIPTION    => 'Check for presence of TSL and GENCODE attributes, and CCDS xrefs',
  GROUPS         => ['core', 'geneset_support_level'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['attrib_type', 'external_db', 'object_xref', 'transcript', 'transcript_attrib', 'xref']
};

sub skip_tests {
  my ($self) = @_;

  if ( $self->species !~ /^(homo_sapiens|mus_musculus)$/ ) {
    return (1, 'GENCODE/TSL/CCDS are only required for human and mouse');
  }
}

sub tests {
  my ($self) = @_;
  my $helper = $self->dba->dbc->sql_helper;

  my $desc_1 = 'All genes have at least one transcript with a %s attribute';
  my $sql_1a = q/
    SELECT COUNT(distinct gene_id) FROM transcript
    WHERE biotype NOT IN ('LRG_gene')
  /;
  my $sql_1b = q/
      SELECT COUNT(DISTINCT gene_id) AS `COUNT(distinct gene_id)`, 'gencode_basic' AS code
      FROM attrib_type
      LEFT JOIN transcript_attrib ta USING (attrib_type_id)
      LEFT JOIN transcript t ON t.transcript_id = ta.transcript_id
      WHERE attrib_type.code IN ('gencode_basic', 'gencode_primary')
      AND (biotype NOT IN ('LRG_gene') OR biotype IS NULL)
      
      UNION ALL
      
      SELECT COUNT(DISTINCT gene_id) AS `COUNT(distinct gene_id)`, 'is_canonical' AS code
      FROM attrib_type
      LEFT JOIN transcript_attrib ta USING (attrib_type_id)
      LEFT JOIN transcript t ON t.transcript_id = ta.transcript_id
      WHERE attrib_type.code = 'is_canonical'
      AND (biotype NOT IN ('LRG_gene') OR biotype IS NULL);

  /;

  my $desc_1c = "Transcript attrib all match gene canonical_transcript_id";
  my $sql_1c = q/
  SELECT ta.transcript_id, 'is_canonical not present in gene' as error
    FROM transcript_attrib ta
      INNER JOIN attrib_type USING (attrib_type_id)
    WHERE
      attrib_type.code = 'is_canonical'
      AND NOT EXISTS (SELECT *
                      FROM gene g
                      WHERE g.canonical_transcript_id = ta.transcript_id)
    UNION
    SELECT g.canonical_transcript_id as transcript_id, 'canonical_transcript with no attribute' as error
    FROM gene g
    WHERE NOT EXISTS (SELECT *
                      FROM transcript_attrib ta
                      INNER JOIN attrib_type USING (attrib_type_id)
                      WHERE g.canonical_transcript_id = ta.transcript_id
                      AND attrib_type.code = 'is_canonical');
  /;
  my $gene_count    = $helper->execute_single_result( -SQL => $sql_1a );
  my $attribs_count = $helper->execute( -SQL => $sql_1b );
  my $desc_1b = "is_canonical, genecode_basic exists in transcript_attrib set";
  my $detail_desc;
  # Expect exactly two lines returned even if zero lines, one per attrib.code
  cmp_ok(scalar @$attribs_count, '==', 2, $desc_1b);
  is_rows_zero($self->dba, $sql_1c, $desc_1c);
  foreach my $attrib_count (@$attribs_count) {
    my ($count, $code) = @$attrib_count;
    $detail_desc = sprintf($desc_1, $code);
    is($count, $gene_count, $detail_desc);
  }


  my $desc_2 = 'TSL attributes exist';
  my $sql_2  = q/
    SELECT COUNT(*) FROM
      transcript INNER JOIN
      transcript_attrib USING (transcript_id) INNER JOIN
      attrib_type USING (attrib_type_id)
    WHERE code like 'tsl%'
  /;
  is_rows_nonzero($self->dba, $sql_2, $desc_2);

  my $desc_3 = 'CCDS xrefs exist';
  my $sql_3  = q/
    SELECT COUNT(*) FROM
      object_xref INNER JOIN
      xref USING (xref_id) INNER JOIN
      external_db USING (external_db_id)
    WHERE db_name = 'CCDS';
  /;
  is_rows_nonzero($self->dba, $sql_3, $desc_3);

}

1;
