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

package Bio::EnsEMBL::DataCheck::Checks::HGNCMultipleGenes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'HGNCMultipleGenes',
  DESCRIPTION    => 'HGNC-derived gene names are not given to multiple genes',
  GROUPS         => ['core', 'xref', 'xref_name_projection'],
  DATACHECK_TYPE => 'advisory',
  TABLES         => ['external_db', 'gene', 'xref']
};

sub tests {
  my ($self) = @_;

  my $dbea = $self->dba->get_adaptor('DBEntry');
  my $hgnc_xrefs = $dbea->fetch_all_by_source("HGNC%");
  
  my $ga = $self->dba->get_adaptor('Gene');
  
  my $count = 0;
  foreach my $xref (@$hgnc_xrefs) {
    next if $xref->display_id =~ /1 to many/;
    my $genes = $ga->fetch_all_by_display_label($xref->display_id);
    if (scalar @{$genes} > 1) {
      $count++;
    }
  }

  my $desc = "All HGNC symbols have been assigned to only one gene";
  is($count, 0, $desc);
}

1;
