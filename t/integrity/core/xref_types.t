# Copyright [2016] EMBL-European Bioinformatics Institute
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

use warnings;
use strict;

use Bio::EnsEMBL::DataTest::TableAwareTest;
use Test::More;
use Bio::EnsEMBL::DataTest::Utils::DBUtils qw/is_query/;

Bio::EnsEMBL::DataTest::TableAwareTest->new(
  name => 'xref_types',
  description =>
    q/Check that xrefs are only attached to one feature type/
  ,
  db_types    => ['core'],
  per_species => 0,
  tables      => [ 'object_xref', 'xref', 'external_db' ],
  test        => sub {
    my ($dba) = @_;

    my $xref_types = {};

    $dba->dbc()->sql_helper()->execute_no_return(
      -SQL => q/select distinct db_name,ensembl_object_type from object_xref ox
    join xref using (xref_id)
    join external_db using (external_db_id)
    /,
      -CALLBACK => sub {
        my ( $name, $type ) = @{ shift @_ };
        push @{ $xref_types->{$name} }, $type;
        return;
      } );
    while ( my ( $name, $types ) = each %$xref_types ) {
      is( 1,
          scalar @$types,
          "Checking $name xrefs are only associated with one object type" );
    }
    return;
  } );
