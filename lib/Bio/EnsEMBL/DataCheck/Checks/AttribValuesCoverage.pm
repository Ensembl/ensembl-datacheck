=head1 LICENSE

Copyright [2018-2020] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::AttribValuesCoverage;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'AttribValuesCoverage',
  DESCRIPTION    => 'TSL and APPRIS covers 95% of protein-coding gene on each chromosome',
  GROUPS         => ['geneset_support_level'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['assembly_exception', 'attrib_type', 'gene', 'seq_region', 'seq_region_attrib', 'transcript', 'transcript_attrib']
};

sub tests {
  my ($self) = @_;
  my $helper = $self->dba->dbc->sql_helper;

  my $desc_1 = '95% of the protein-coding genes on each chromosome have APPRIS attributes';
  my $sql_1a = q/
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
  my $sql_1b = q/
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
  row_subtotals($self->dba, undef, $sql_1a, $sql_1b, 0.95, $desc_1);

  if ($self->species =~ /(homo_sapiens|mus_musculus)/) {

    my $desc_2 = '95% of the protein-coding genes on each chromosome have TSL attributes';
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
        at2.code like 'tsl%'
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
  }
}

1;
