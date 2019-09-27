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

package Bio::EnsEMBL::DataCheck::Checks::TagCoverageStats;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'TagCoverageStats',
  DESCRIPTION    => 'The coverage must not exceed the genome lengths',
  GROUPS        => ['compara', 'compara_pairwise_alignments'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['method_link_species_set_tag', 'species_tree_node_tag'],
};

sub tests {
  my ($self) = @_;

  my $desc_1 = "Table method_link_species_set_tag: ref_genome_coverage <= ref_genome_length";
  my $sql_1 = q/
  SELECT COUNT(*) FROM method_link_species_set_tag coverage
    INNER JOIN method_link_species_set_tag length
      ON coverage.method_link_species_set_id=length.method_link_species_set_id
  WHERE coverage.tag="ref_genome_coverage"
    AND length.tag="ref_genome_length" AND
    CAST(coverage.value AS SIGNED) > CAST(length.value AS SIGNED);
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);
  my $desc_2 = "Table method_link_species_set_tag: (ref_matches+ref_mis_matches+ref_insertions) <= (ref_coding_exon_length - ref_uncovered)";
  my $sql_2 = q/
  SELECT COUNT(*) FROM method_link_species_set_tag matches
    INNER JOIN method_link_species_set_tag mis
      ON matches.method_link_species_set_id=mis.method_link_species_set_id
    INNER JOIN method_link_species_set_tag ins
      ON mis.method_link_species_set_id=ins.method_link_species_set_id
    INNER JOIN method_link_species_set_tag exon
      ON ins.method_link_species_set_id=exon.method_link_species_set_id
    INNER JOIN method_link_species_set_tag unc
      ON exon.method_link_species_set_id=unc.method_link_species_set_id
  WHERE matches.tag="ref_matches"
    AND mis.tag="ref_mis_matches"
    AND ins.tag="ref_insertions"
    AND exon.tag="ref_coding_exon_length"
    AND unc.tag="ref_uncovered"
    AND ((CAST(matches.value AS SIGNED) + CAST(mis.value AS SIGNED) + CAST(ins.value AS SIGNED)) > (CAST(exon.value AS SIGNED) - CAST(unc.value AS SIGNED)));
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2);
  my $desc_3 = "Table method_link_species_set_tag: ref_covered <= (ref_coding_length - ref_uncovered)";
  my $sql_3 = q/
  SELECT COUNT(*) FROM method_link_species_set_tag cov
    INNER JOIN method_link_species_set_tag exon
      ON cov.method_link_species_set_id=exon.method_link_species_set_id
    INNER JOIN method_link_species_set_tag unc
      ON exon.method_link_species_set_id=unc.method_link_species_set_id
  WHERE cov.tag="ref_covered"
    AND exon.tag="ref_coding_exon_length"
    AND unc.tag="ref_uncovered"
    AND CAST(cov.value AS SIGNED) > (CAST(exon.value AS SIGNED) - CAST(unc.value AS SIGNED));
  /;
  is_rows_zero($self->dba, $sql_3, $desc_3);
  my $desc_4 = "Table method_link_species_set_tag: non_ref_genome_coverage <= non_ref_genome_length";
  my $sql_4 = q/
  SELECT COUNT(*) FROM method_link_species_set_tag coverage
    INNER JOIN method_link_species_set_tag length
      ON coverage.method_link_species_set_id=length.method_link_species_set_id
  WHERE coverage.tag="non_ref_genome_coverage"
    AND length.tag="non_ref_genome_length" AND
    CAST(coverage.value AS SIGNED) > CAST(length.value AS SIGNED);
  /;
  is_rows_zero($self->dba, $sql_4, $desc_4);
  my $desc_5 = "Table method_link_species_set_tag: (non_ref_matches+non_ref_mis_matches+non_ref_insertions) <= (non_ref_coding_exon_length - non_ref_uncovered)";
  my $sql_5 = q/
  SELECT COUNT(*) FROM method_link_species_set_tag matches
    INNER JOIN method_link_species_set_tag mis
      ON matches.method_link_species_set_id=mis.method_link_species_set_id
    INNER JOIN method_link_species_set_tag ins
      ON mis.method_link_species_set_id=ins.method_link_species_set_id
    INNER JOIN method_link_species_set_tag exon
      ON ins.method_link_species_set_id=exon.method_link_species_set_id
    INNER JOIN method_link_species_set_tag unc
      ON exon.method_link_species_set_id=unc.method_link_species_set_id
  WHERE matches.tag="non_ref_matches"
    AND mis.tag="non_ref_mis_matches"
    AND ins.tag="non_ref_insertions"
    AND exon.tag="non_ref_coding_exon_length"
    AND unc.tag="non_ref_uncovered"
    AND ((CAST(matches.value AS SIGNED) + CAST(mis.value AS SIGNED) + CAST(ins.value AS SIGNED)) > (CAST(exon.value AS SIGNED) - CAST(unc.value AS SIGNED)));
  /;
  is_rows_zero($self->dba, $sql_5, $desc_5);
  my $desc_6 = "Table method_link_species_set_tag: non_ref_covered <= (non_ref_coding_length - non_ref_uncovered)";
  my $sql_6 = q/
  SELECT COUNT(*) FROM method_link_species_set_tag cov
    INNER JOIN method_link_species_set_tag exon
      ON cov.method_link_species_set_id=exon.method_link_species_set_id
    INNER JOIN method_link_species_set_tag unc
      ON exon.method_link_species_set_id=unc.method_link_species_set_id
  WHERE cov.tag="non_ref_covered"
    AND exon.tag="non_ref_coding_exon_length"
    AND unc.tag="non_ref_uncovered"
    AND CAST(cov.value AS SIGNED) > (CAST(exon.value AS SIGNED) - CAST(unc.value AS SIGNED));
  /;
  is_rows_zero($self->dba, $sql_6, $desc_6);
  my $desc_7 = "Table species_tree_node_tag: genome_coverage <= genome_length";
  my $sql_7 = q/
  SELECT COUNT(*) FROM species_tree_node_tag coverage
    INNER JOIN species_tree_node_tag length
      ON coverage.node_id=length.node_id
  WHERE coverage.tag="genome_coverage"
    AND length.tag="genome_length"
    AND (CAST(coverage.value AS SIGNED) > CAST(length.value AS SIGNED));
  /;
  is_rows_zero($self->dba, $sql_7, $desc_7);
  my $desc_8 = "Table species_tree_node_tag: coding_exon_coverage <= coding_exon_length";
  my $sql_8 = q/
  SELECT COUNT(*) FROM species_tree_node_tag coverage
    INNER JOIN species_tree_node_tag length
      ON coverage.node_id=length.node_id
  WHERE coverage.tag="coding_exon_coverage"
    AND length.tag="coding_exon_length"
    AND (CAST(coverage.value AS SIGNED) > CAST(length.value AS SIGNED))
  /;
  is_rows_zero($self->dba, $sql_8, $desc_8);
}
1;
