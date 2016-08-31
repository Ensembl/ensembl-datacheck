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
use Bio::EnsEMBL::DataTest::Utils::DBUtils qw/get_species_ids is_rowcount_zero/;
use Data::Dumper;

Bio::EnsEMBL::DataTest::TableAwareTest->new(
  name     => 'assembly_mapping',
  db_types => ['core'],
  tables   => [ 'meta', 'coord_system' ],
  test     => sub {
    my ($dba) = @_;

    my $id = $dba->species_id();

    # valid cs name or name:version pattern
    my $assembly_pattern = qr/([^:]+)(:(.+))?/;
    my $default_version  = 'NONE';
    # fetch name->version (set version to NONE if null)
    my $coord_systems =
      $dba->dbc()->sql_helper()->execute_into_hash(
      -SQL =>
qq/select name,ifnull(version,'$default_version') from coord_system where species_id=?/,
      -PARAMS => [$id] );

    # check for null/empty mappings
    is_rowcount_zero(
      $dba,
"select count(*) from meta where species_id=$id and meta_key='assembly.mapping' 
        and (meta_value is null or meta_value='')",
      "Checking for null or empty assembly.mapping values" );

    # for each mapping
    for my $mapping (
      @{$dba->dbc()->sql_helper()->execute_simple(
          -SQL =>
q/select meta_value from meta where species_id=? and meta_key='assembly.mapping' 
        and meta_value is not null and meta_value<>''/,
          -PARAMS => [$id] ) } )
    {
      # split the mapping on | or #
      for my $map_element ( split( /[|#]/, $mapping ) ) {
        # check each element
        ok( $map_element =~ $assembly_pattern,
            "Checking if mapping matches expected pattern" );
        my ( $name, $fv, $version ) = $map_element =~ $assembly_pattern;
        $version ||= $default_version;
        is( $coord_systems->{$name},
            $version, "Checking for coord_system and version" );
      }
    }

    return;
  } );
