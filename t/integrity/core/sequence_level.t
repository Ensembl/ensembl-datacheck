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
  name     => 'lrg',
  db_types => ['core'],
  tables   => [ 'seq_region', 'coord_system', 'dna' ],
  test     => sub {
    my ($dba) = @_;
    
    is_query(
      $dba,0,
"SELECT count(*) FROM coord_system WHERE name = 'contig' AND version is not NULL and species_id="
        . $dba->species_id(),
      'Checking for contig coord_systems with non-null versions' );

    # check for coordinate_systems with DNA where sequence_level not set
    for my $loose_system (
      @{$dba->dbc()->sql_helper()->execute_simple(
          -SQL => qq/SELECT distinct cs.name FROM coord_system cs 
    JOIN seq_region s USING (coord_system_id)
    JOIN dna d using (seq_region_id) 
    WHERE cs.attrib NOT LIKE '%sequence_level%' and species_id=?/,
          -PARAMS => [ $dba->species_id() ] ) } )
    {
      fail(
"Coordinate system $loose_system has seq_regions containing sequence but no sequence_level attribute"
      );
    }
    return;
  } );
