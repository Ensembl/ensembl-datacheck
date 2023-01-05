=head1 LICENSE

Copyright [2018-2023] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CompareHGNCMultipleGenes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareHGNCMultipleGenes',
  DESCRIPTION    => 'HGNC-derived gene names assigned to multiple genes have not increased more than 5%',
  GROUPS         => ['compare_core', 'xref', 'xref_name_projection'],
  DATACHECK_TYPE => 'advisory',
  TABLES         => ['external_db', 'gene', 'xref']
};

sub tests {
  my ($self) = @_;

  my $cur_dba = $self->dba;
  my $old_dba = $self->get_old_dba();

  my $cur_multi_hgnc_percentage = $self->multiple_hgnc_percentage($cur_dba);
  my $old_multi_hgnc_percentage = 0;

  if (defined $old_dba) {
    $old_multi_hgnc_percentage = $self->multiple_hgnc_percentage($old_dba);
  }

  my $multi_hgnc_diff = $cur_multi_hgnc_percentage - $old_multi_hgnc_percentage;

  my $desc = "HGNC symbols assigned to multiple genes have not increased more than 5%";
  cmp_ok($multi_hgnc_diff, "<=", 5, $desc);
}

sub multiple_hgnc_percentage {
  my ($self, $db_adaptor) = @_;

  my $dbea = $db_adaptor->get_adaptor('DBEntry');
  my $ga = $db_adaptor->get_adaptor('Gene');
  my $hgnc_xrefs = $dbea->fetch_all_by_source("HGNC%");

  my $multi_genes = 0;
  my $all_symbols = 0;
  foreach my $xref (@$hgnc_xrefs) {
    next if $xref->display_id =~ /1 to many/;
    $all_symbols++;
    my $genes = $ga->fetch_all_by_display_label($xref->display_id);
    if (scalar @{$genes} > 1) {
      $multi_genes++;
    }
  }
  if ($all_symbols == 0) {
    return 0;
  }
  return $multi_genes / $all_symbols * 100;
}

1;
