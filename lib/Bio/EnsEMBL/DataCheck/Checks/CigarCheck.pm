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

package Bio::EnsEMBL::DataCheck::Checks::CigarCheck;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CigarCheck',
  DESCRIPTION    => 'The cigar_line must not have negative numbers or zeros in it',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_genome_alignments', 'compara_homology_annotation', 'compara_blastocyst'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['family_member', 'gene_align_member', 'genomic_align', 'homology_member', 'peptide_align_feature'],
};

sub tests {
  my ($self) = @_;

  my @cigar_tables = ('family_member', 'gene_align_member', 'genomic_align', 'homology_member', 'peptide_align_feature');
  foreach my $table (@cigar_tables) {

    my $desc = "Column $table.cigar_line has no negative values";
    my $sql_2 = qq/
      SELECT COUNT(*) FROM
        $table
      WHERE
        cigar_line LIKE '%-%'
    /;
    if ($table eq "gene_align_member") {
      $sql_2 = qq/
      SELECT COUNT(*) FROM
        gene_align_member g INNER JOIN
        gene_align a ON a.gene_align_id=g.gene_align_id
      WHERE NOT aln_method="mcoffee_score" AND
        cigar_line LIKE '%-%'
      /;
    }
    is_rows_zero($self->dba, $sql_2, $desc);

    my $desc_2 = "Column $table.cigar_line does not contain a zero";
    my $sql_3 = qq/
      SELECT COUNT(*) FROM
        $table
      WHERE
        (cigar_line REGEXP '^[0]' OR cigar_line REGEXP '[A-Z][0]')
    /;
    if ($table eq "gene_align_member") {
      $sql_3 = qq/
      SELECT COUNT(*) FROM
        gene_align_member g INNER JOIN
        gene_align a ON a.gene_align_id=g.gene_align_id
      WHERE NOT aln_method="mcoffee_score" AND
        (cigar_line REGEXP '^[0]' OR cigar_line REGEXP '[A-Z][0]')
      /;
    }
    is_rows_zero($self->dba, $sql_3, $desc_2);

  }
}
1;
