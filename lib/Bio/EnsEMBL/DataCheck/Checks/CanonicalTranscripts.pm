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

package Bio::EnsEMBL::DataCheck::Checks::CanonicalTranscripts;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'CanonicalTranscripts',
  DESCRIPTION => 'Canonical transcripts and translation are correctly configured',
  GROUPS      => ['core', 'brc4_core', 'geneset'],
  DB_TYPES    => ['core'],
  TABLES      => ['attrib_type', 'coord_system', 'exon', 'exon_transcript', 'gene', 'seq_region', 'transcript', 'transcript_attrib', 'translation']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc_1 = 'Canonical transcript belongs to gene';
  my $sql_1  = qq/
    SELECT g.stable_id FROM
      gene g INNER JOIN
      transcript t ON g.canonical_transcript_id = t.transcript_id INNER JOIN
      seq_region sr ON g.seq_region_id = sr.seq_region_id INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      g.gene_id <> t.gene_id AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);

  my $desc_2 = 'Canonical translation belongs to transcript';
  my $sql_2  = qq/
    SELECT tt.stable_id FROM
      transcript tt INNER JOIN
      translation tn ON tt.canonical_translation_id = tn.translation_id INNER JOIN
      seq_region sr ON tt.seq_region_id = sr.seq_region_id INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      tt.transcript_id <> tn.transcript_id AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2);

  my $sql_3  = qq/
    SELECT g.stable_id FROM
      gene g INNER JOIN
      transcript tt ON g.canonical_transcript_id = tt.transcript_id INNER JOIN
      translation tn on tt.transcript_id = tn.transcript_id INNER JOIN
      biotype b ON g.biotype = b.name INNER JOIN
      seq_region sr ON g.seq_region_id = sr.seq_region_id INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      g.biotype <> 'LRG_gene' AND
      b.object_type = 'gene' AND
      b.biotype_group <> 'coding' AND
      cs.species_id = $species_id
  /;
  my $mca = $self->dba->get_adaptor('MetaContainer');
  if($mca->single_value_by_key('genebuild.method') eq 'projection_build'){
        skip "Canonical transcript checks are  not mandatory for projection builds", 1;
	}
	else{
		 my $desc_3 = 'Canonical transcripts with translations belong to protein-coding genes';
		 is_rows_zero($self->dba, $sql_3, $desc_3);
	 }
 

  my $desc_4 = 'Canonical transcripts with translations are protein-coding';
  my $sql_4  = qq/
    SELECT g.stable_id FROM
      gene g INNER JOIN
      transcript tr ON g.canonical_transcript_id = tr.transcript_id INNER JOIN
      translation tl ON tr.transcript_id = tl.transcript_id INNER JOIN
      biotype b ON tr.biotype = b.name INNER JOIN
      seq_region sr ON g.seq_region_id = sr.seq_region_id INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      g.biotype <> 'LRG_gene' AND
      b.object_type = 'transcript' AND
      b.biotype_group <> 'coding' AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_4, $desc_4);

  my $desc_5 = 'Protein-coding genes have protein-coding canonical transcripts';
  my $sql_5  = qq/
    SELECT g.stable_id FROM
	  gene g INNER JOIN
	  transcript t ON g.canonical_transcript_id = t.transcript_id INNER JOIN
      seq_region sr ON g.seq_region_id = sr.seq_region_id INNER JOIN
      coord_system cs USING (coord_system_id)
	WHERE
      g.biotype = 'protein_coding' AND
	  t.biotype NOT IN ('protein_coding', 'nonsense_mediated_decay', 'protein_coding_LoF') AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_5, $desc_5);


  my $helper = $self->dba->dbc->sql_helper;

  my $desc_6a = "is_canonical exists in attrib_type set";
  my $sql_6a = q/
    SELECT COUNT(*) FROM attrib_type
    WHERE code = 'is_canonical'
  /;

  my $desc_6b = 'All genes have at least one transcript with an is_canonical attribute';
  my $sql_6b = q/
    SELECT COUNT(distinct gene_id) FROM transcript
    WHERE biotype NOT IN ('LRG_gene')
  /;
  my $sql_6c = q/
      SELECT COUNT(distinct gene_id)
      FROM attrib_type
        LEFT JOIN transcript_attrib ta USING (attrib_type_id)
        LEFT JOIN transcript t on t.transcript_id = ta.transcript_id AND biotype NOT IN ('LRG_gene')
      WHERE
        attrib_type.code = 'is_canonical';
  /;

  my $desc_6d = "All is_canonical transcript attrib values match gene canonical_transcript_id";
  my $sql_6d = q/
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

  my $attrib_type_count = $helper->execute_single_result( -SQL => $sql_6a );
  is($attrib_type_count, 1, $desc_6a);

  my $gene_count = $helper->execute_single_result( -SQL => $sql_6b );
  my $attrib_count = $helper->execute_single_result( -SQL => $sql_6c );
  is($attrib_count, $gene_count, $desc_6b);

  is_rows_zero($self->dba, $sql_6d, $desc_6d);

}

1;
