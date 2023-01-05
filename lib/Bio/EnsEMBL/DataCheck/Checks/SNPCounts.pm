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

package Bio::EnsEMBL::DataCheck::Checks::SNPCounts;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SNPCounts',
  DESCRIPTION => 'SNP counts are correct',
  GROUPS      => ['statistics', 'variation_statistics'],
  DB_TYPES    => ['core'],
  FORCE       => 1
};

sub tests {
  my ($self) = @_;

  SKIP: {
    my $var_dba = $self->get_dba(undef, 'variation');
    skip 'No variation database', 1 unless defined $var_dba;

    my $sa = $self->dba->get_adaptor('Slice');

    my $slices = $sa->fetch_all_karyotype();
    skip 'No chromosomes, therefore no SNP counts', 1 unless scalar(@$slices);

    foreach my $slice (@$slices) {
      my $sr_name = $slice->coord_system_name . ' ' . $slice->seq_region_name;
      my $desc = "SNP counts match for $sr_name in core and variation databases";

      my ($attrib) = @{$slice->get_all_Attributes('SNPCount')};
      my $sum = defined $attrib ? $attrib->value() : 0;

      my $var_sql = 'SELECT COUNT(*) FROM variation_feature WHERE seq_region_id = ?';
      my $sth = $var_dba->dbc->prepare($var_sql);
      $sth->execute($slice->get_seq_region_id);
      my ($count) = $sth->fetchrow_array();

      is($sum, $count, $desc);
    }
  }
}

1;
