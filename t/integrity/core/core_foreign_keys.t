# Copyright [2016] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use warnings;
use strict;

use Bio::EnsEMBL::DataTest::TableAwareTest;
use Test::More;
use Bio::EnsEMBL::DataTest::Utils::DBUtils
  qw/rowcount is_rowcount_nonzero is_rowcount_zero ok_foreignkeys/;
use Data::Dumper;
use Bio::EnsEMBL::DataTest::Utils::TableSets
  qw/get_tables_with_analysis_id get_object_xref_tables get_core_foreign_keys/;

Bio::EnsEMBL::DataTest::TableAwareTest->new(
  name     => 'core_foreign_keys',
  db_types => [ 'core', 'otherfeatures' ],
  tables =>
    [ @{ get_object_xref_tables() }, @{ get_tables_with_analysis_id() } ],
  test => sub {
    my ($dba) = @_;
    while ( my ( $table, $keys_list ) = each %{ get_core_foreign_keys() } ) {
      for my $keys ( @{$keys_list} ) {
        ok_foreignkeys( $dba, $table, $keys->{col1}, $keys->{table2},
                        $keys->{col2}, $keys->{both_ways},
                        $keys->{constraint} );
      }
    }
    return;
  } );
