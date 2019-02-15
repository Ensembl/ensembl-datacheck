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

package Bio::EnsEMBL::DataCheck::Checks::GeneGC;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'GeneGC',
  DESCRIPTION => 'All genes have a GC statistic',
  GROUPS      => ['statistics'],
  DB_TYPES    => ['core'],
  TABLES      => ['attrib_type', 'gene', 'gene_attrib']
};

sub tests {
  my ($self) = @_;

  my $code = 'GeneGC';

  my $aa     = $self->dba->get_adaptor('Attribute');
  my $attrib = $aa->fetch_by_code($code);

  my $desc_1 = "$code attribute exists";
  ok(scalar(@$attrib), $desc_1);

  my $attrib_type_id = $$attrib[0];
  my $species_id     = $self->dba->species_id;

  my $desc_2 = "All genes have $code attribute";
  my $sql_2a = qq/
    SELECT COUNT(*) FROM
      gene INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id)
    WHERE
      biotype <> 'LRG_gene' AND
      species_id = $species_id
  /;
  my $sql_2b = qq/
    SELECT COUNT(*) FROM
      gene INNER JOIN
      gene_attrib USING (gene_id) INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id) 
    WHERE
      species_id = $species_id AND
      attrib_type_id = $attrib_type_id
  /;
  row_totals($self->dba, undef, $sql_2a, $sql_2b, 1, $desc_2);

  # We do not check for non-zero values, because we may get a gene
  # (most likely a partial gene) that is all As and Ts.
  my $desc_3 = "All $code attributes have defined value";
  my $sql_3 = qq/
    SELECT COUNT(*) FROM
      gene INNER JOIN
      gene_attrib USING (gene_id) INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id) 
    WHERE
      species_id = $species_id AND
      attrib_type_id = $attrib_type_id AND
      value is null
  /;
  is_rows_zero($self->dba, $sql_3, $desc_3);

  # It's possible to write the tests using the API, but there aren't really
  # any methods that are sufficiently quick; we have to iterate over all the
  # genes. Since I gave it a go, I might as well leave the code here for
  # future reference.

  #my ($gene_count, $attrib_count, $value_count) = (0, 0, 0);
  #my $ga = $self->dba->get_adaptor('Gene');
  #foreach my $gene ( @{$ga->fetch_all} ) {
  #  $gene_count++;
  #  my $attribs = $aa->fetch_all_by_Gene($gene, $code);
  #  if (scalar(@$attribs)) {
  #    $attrib_count++;
  #    if ($$attribs[0]->value) {
  #      $value_count++;
  #    }
  #  }
  #}

  #my $desc_2 = "All genes have $code attribute";
  #is($gene_count, $attrib_count, $desc_2);

  #my $desc_3 = "All $code attributes have defined, non-zero, value";
  #is($attrib_count, $value_count, $desc_3);
}

1;
