=head1 LICENSE

# Copyright [2018] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

=cut

package Bio::EnsEMBL::DataCheck::Checks::CoreForeignKeys;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';
  
use Bio::EnsEMBL::DataCheck::Utils::TableSets
  qw/get_tables_with_analysis_id get_object_xref_tables get_core_foreign_keys/;

use constant {
  NAME        => 'CoreForeignKeys',
  DESCRIPTION => 'Check for incorrect foreign key relationships.',
  DB_TYPES    => ['core', 'otherfeatures'],
  TABLES      => [@{ get_object_xref_tables() }, @{ get_tables_with_analysis_id() }],
  GROUPS      => ['handover'],
};

sub tests {
  my ($self) = @_;
  my $dba = $self->dba;

  while ( my ( $table, $keys_list ) = each %{ get_core_foreign_keys() } ) {
    for my $keys ( @{$keys_list} ) {
      fk( $dba, $table, $keys->{col1}, $keys->{table2},
                      $keys->{col2}, $keys->{both_ways},
                      $keys->{constraint} );
    }
  }
}

1;
