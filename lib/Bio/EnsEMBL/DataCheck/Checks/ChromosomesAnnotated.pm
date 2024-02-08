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

package Bio::EnsEMBL::DataCheck::Checks::ChromosomesAnnotated;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'ChromosomesAnnotated',
  DESCRIPTION    => 'Chromosomal seq_regions have appropriate attribute',
  GROUPS         => ['assembly', 'core', 'brc4_core'],
  DB_TYPES       => ['core'],
  TABLES         => ['attrib_type', 'coord_system', 'seq_region', 'seq_region_attrib']
};

sub tests {
  my ($self) = @_;

  my $sa = $self->dba->get_adaptor('Slice');

  my $mca = $self->dba->get_adaptor('MetaContainer');
  my $cs_version = $mca->single_value_by_key('assembly.default');

  my @chromosomal = ('chromosome', 'chromosome_group', 'plasmid');

  foreach my $cs_name (@chromosomal) {
    my $slices = $sa->fetch_all($cs_name, $cs_version);
    foreach (@$slices) {
      # seq_regions that are not genuine biological chromosomes,
      # but are instead collections of unmapped sequence,
      # have a 'chromosome' attribute - these regions do not
      # necessarily need a karyotype_rank attribute.
      my @non_bio_chr = @{$_->get_all_Attributes('chromosome')};
      next if scalar(@non_bio_chr);

      my $sr_name = $_->seq_region_name;
      my $desc = "$cs_name $sr_name has 'karyotype_rank' attribute";
      ok($_->has_karyotype, $desc);
    }
  }

  $self->karyotype_rank_cardinality();
}

sub karyotype_rank_cardinality {
  my ($self) = @_;

  # This is a separate check because 'primary_assembly' regions
  # need to be tested, as well those marked as 'chromosomes'.
  my $desc = "Regions have only one 'karyotype_rank' attribute";
  my $diag = "Regions with multiple 'karyotype_rank' attributes";
  my $sql  = q/
    SELECT seq_region_id, COUNT(*) FROM
      seq_region_attrib sra INNER JOIN
      attrib_type at USING (attrib_type_id)
    WHERE
      at.code = 'karyotype_rank'
    GROUP BY
      sra.seq_region_id
    HAVING COUNT(*) > 1;
  /;

  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;
