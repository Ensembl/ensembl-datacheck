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

package Bio::EnsEMBL::DataCheck::Checks::AttribValues;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'AttribValues',
  DESCRIPTION    => 'TSL, APPRIS, GENCODE and RefSeq attributes exist',
  GROUPS         => ['geneset'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['assembly_exception', 'attrib_type', 'coord_system', 'gene', 'gene_attrib', 'seq_region', 'seq_region_attrib', 'transcript', 'transcript_attrib']
};

sub skip_tests {
  my ($self) = @_;

  my @applicable_species = qw/
    homo_sapiens
    mus_musculus
    danio_rerio
    rattus_norvegicus
    sus_scrofa
  /;

  my %applicable_species = map { $_ => 1 } @applicable_species;

  if ( ! exists $applicable_species{$self->species} ) {
    return (1, 'Attribute types not applicable.');
  }
}

sub tests {
  my ($self) = @_;
  my $helper = $self->dba->dbc->sql_helper;

  my $desc_1 = 'APPRIS attributes exist';
  my $sql_1  = q/
    SELECT COUNT(*) FROM
      transcript INNER JOIN
      transcript_attrib USING (transcript_id) INNER JOIN
      attrib_type USING (attrib_type_id)
    WHERE code like 'appris%'
  /;
  is_rows_nonzero($self->dba, $sql_1, $desc_1);

  my $desc_2 = '95% of the protein-coding genes on each chromosome have APPRIS attributes';
  my $sql_2a = q/
    SELECT sr.name, COUNT(DISTINCT g.stable_id) FROM
      gene g INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      seq_region_attrib sra USING (seq_region_id) INNER JOIN
      attrib_type at ON sra.attrib_type_id = at.attrib_type_id INNER JOIN
      transcript t USING (gene_id) INNER JOIN
      transcript_attrib ta USING (transcript_id) INNER JOIN
      attrib_type at2 ON ta.attrib_type_id = at2.attrib_type_id
    WHERE
      g.biotype = 'protein_coding' AND
      at.code = 'karyotype_rank' AND
      at2.code like 'appris%'
    GROUP BY sr.name
  /;
  my $sql_2b = q/
    SELECT sr.name, COUNT(DISTINCT g.stable_id) FROM
      gene g INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      seq_region_attrib sra USING (seq_region_id) INNER JOIN
      attrib_type at ON sra.attrib_type_id = at.attrib_type_id
    WHERE
      g.biotype = 'protein_coding' AND
      at.code = 'karyotype_rank'
    GROUP BY sr.name
  /;
  row_subtotals($self->dba, undef, $sql_2a, $sql_2b, 0.95, $desc_2);

  my $desc_3 = 'All genes have at least one transcript with a refseq_compare attribute';
  my $sql_3a = q/
    SELECT COUNT(distinct g.gene_id) FROM
      gene g INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      cs.name = 'chromosome' AND
      cs.attrib = 'default_version' AND
      sr.name NOT LIKE 'LRG%' AND
      sr.name != 'MT' AND
      sr.seq_region_id NOT IN 
        (SELECT seq_region_id FROM assembly_exception
        WHERE exc_type in ('PATCH_NOVEL', 'PATCH_FIX', 'HAP'))
  /;
  my $sql_3b = q/
    SELECT COUNT(distinct g.gene_id) FROM
      gene g INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id) INNER JOIN
      gene_attrib ga USING (gene_id) INNER JOIN
      attrib_type at USING (attrib_type_id)
    WHERE
      cs.name = 'chromosome' AND
      cs.attrib = 'default_version' AND
      sr.name NOT LIKE 'LRG%' AND
      sr.name != 'MT' AND
      sr.seq_region_id NOT IN
        (SELECT seq_region_id FROM assembly_exception
        WHERE exc_type in ('PATCH_NOVEL', 'PATCH_FIX', 'HAP')) AND
      at.code = 'refseq_compare'
  /;

  my $gene_count   = $helper->execute_single_result( -SQL => $sql_3a );
  my $refseq_count = $helper->execute_single_result( -SQL => $sql_3b );
  is($refseq_count, $gene_count, $desc_3);

  if ($self->species =~ /(homo_sapiens|mus_musculus)/) {
    my $desc_4 = 'All genes have at least one transcript with a gencode_basic attribute';
    my $sql_4a = q/
      SELECT COUNT(distinct gene_id) FROM transcript
      WHERE biotype NOT IN ('LRG_gene')
    /;
    my $sql_4b = q/
      SELECT COUNT(distinct gene_id) FROM
        transcript INNER JOIN
        transcript_attrib USING (transcript_id) INNER JOIN
        attrib_type USING (attrib_type_id) 
      WHERE
        biotype NOT IN ('LRG_gene') AND
        attrib_type.code = 'gencode_basic'
    /;

    my $gene_count    = $helper->execute_single_result( -SQL => $sql_4a );
    my $gencode_count = $helper->execute_single_result( -SQL => $sql_4b );
    is($gencode_count, $gene_count, $desc_4);

    my $desc_5 = 'TSL attributes exist';
    my $sql_5  = q/
      SELECT COUNT(*) FROM
        transcript INNER JOIN
        transcript_attrib USING (transcript_id) INNER JOIN
        attrib_type USING (attrib_type_id)
      WHERE code like 'tsl%'
    /;
    is_rows_nonzero($self->dba, $sql_5, $desc_5);

    my $desc_6 = '95% of the protein-coding genes on each chromosome have APPRIS attributes';
    my $sql_6a = q/
      SELECT sr.name, COUNT(DISTINCT g.stable_id) FROM
        gene g INNER JOIN
        seq_region sr USING (seq_region_id) INNER JOIN
        seq_region_attrib sra USING (seq_region_id) INNER JOIN
        attrib_type at ON sra.attrib_type_id = at.attrib_type_id INNER JOIN
        transcript t USING (gene_id) INNER JOIN
        transcript_attrib ta USING (transcript_id) INNER JOIN
        attrib_type at2 ON ta.attrib_type_id = at2.attrib_type_id
      WHERE
        g.biotype = 'protein_coding' AND
        at.code = 'karyotype_rank' AND
        at2.code like 'tsl%'
      GROUP BY sr.name
    /;
    my $sql_6b = q/
      SELECT sr.name, COUNT(DISTINCT g.stable_id) FROM
        gene g INNER JOIN
        seq_region sr USING (seq_region_id) INNER JOIN
        seq_region_attrib sra USING (seq_region_id) INNER JOIN
        attrib_type at ON sra.attrib_type_id = at.attrib_type_id
      WHERE
        g.biotype = 'protein_coding' AND
        at.code = 'karyotype_rank'
      GROUP BY sr.name
    /;
    row_subtotals($self->dba, undef, $sql_6a, $sql_6b, 0.95, $desc_6);
  }
}

1;
