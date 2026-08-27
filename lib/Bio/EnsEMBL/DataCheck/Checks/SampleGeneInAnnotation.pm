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

package Bio::EnsEMBL::DataCheck::Checks::SampleGeneInAnnotation;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SampleGeneInAnnotation',
  DESCRIPTION => 'The genebuild.sample_gene metadata identifies exactly one gene in the annotation',
  GROUPS      => ['core', 'geneset', 'meta_sample'],
  DB_TYPES    => ['core'],
  TABLES      => ['gene', 'meta']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc_1 = "genebuild.sample_gene metadata exists exactly once and is non-NULL";
  my $diag_1 = "Invalid genebuild.sample_gene metadata (expected exactly one non-NULL value)";
  my $sql_1 = qq/
    SELECT 'genebuild.sample_gene' AS meta_key, row_count, null_count
      FROM (
        SELECT COUNT(*) AS row_count,
               COALESCE(SUM(meta_value IS NULL), 0) AS null_count
          FROM meta
         WHERE species_id = $species_id
           AND meta_key = 'genebuild.sample_gene'
      ) AS counts
     WHERE row_count <> 1 OR null_count <> 0
  /;

  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  my $desc_2 = "genebuild.sample_gene value exists in gene.stable_id";
  my $diag_2 = "Missing annotation gene for genebuild.sample_gene";
  my $sql_2 = qq/
    SELECT m.meta_value
      FROM meta m
 LEFT JOIN gene g ON g.stable_id = m.meta_value
     WHERE m.species_id = $species_id
       AND m.meta_key = 'genebuild.sample_gene'
       AND m.meta_value IS NOT NULL
       AND g.gene_id IS NULL
  /;

  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);
}

1;
