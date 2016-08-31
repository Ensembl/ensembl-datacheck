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

sub ok_lrg_annotations {
  my ( $dba, $feature ) = @_;

# Retrieve all the coordinate systems with that have sequences with features that have biotype LRG.
  my $lrg_coord_systems_sql = qq/SELECT distinct cs.name FROM coord_system cs
    JOIN seq_region sr USING (coord_system_id)
    JOIN $feature f using (seq_region_id)
    WHERE f.biotype LIKE 'LRG%' and cs.species_id=?/;

  foreach my $coord_system ( @{$dba->dbc()->sql_helper()->execute_simple(
                                               -SQL => $lrg_coord_systems_sql,
                                               -PARAMS => [ $dba->species_id() ]
                               ) } )
  {
    is( 'lrg', $coord_system,
        'Checking if coordinate system with LRG features is lrg' );
  }

# now retrieve all the biotypes of all the features that are mapped on the lrg coordinate system.
  my $biotype_sql = qq/SELECT distinct f.biotype FROM coord_system cs
                                        JOIN seq_region sr USING (coord_system_id)
                                        JOIN $feature f USING (seq_region_id)
                                        WHERE cs.name = 'lrg' and cs.species_id=?/;

  for my $biotype (
        @{ $dba->dbc()->sql_helper()->execute_simple( -SQL => $biotype_sql ) } )
  {
    ok( $biotype =~ m/LRG/, "Checking biotype '$biotype' contains LRG" );
  }

  return;

} ## end sub ok_lrg_annotations

Bio::EnsEMBL::DataTest::TableAwareTest->new(
  name     => 'lrg',
  db_types => ['core'],
  tables   => [ 'seq_region', 'coord_system', 'gene', 'transcript' ],
  test     => sub {
    my ($dba) = @_;
    if (
      $dba->dbc()->sql_helper()->execute_single_result(
        -SQL => q/SELECT count(sr.seq_region_id) FROM coord_system cs
                         JOIN seq_region sr USING (coord_system_id)
                         WHERE cs.name = 'lrg' and cs.species_id=?/,
        -PARAMS => [ $dba->species_id() ] ) > 0 )
    {
      ok_lrg_annotations( $dba, 'gene' );
      ok_lrg_annotations( $dba, 'transcript' );
    }
    else {
      diag(" No LRGs found ");
    }

    return;
  } );

