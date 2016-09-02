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

use Bio::EnsEMBL::DataTest::CompareDbTest;
use Test::More;
use Bio::EnsEMBL::DataTest::Utils::DBUtils qw/is_same_counts/;

Bio::EnsEMBL::DataTest::CompareDbTest->new(
  name     => 'compare_previous_biotypes',
  db_types => ['core'],
  tables   => ['gene'],
  test     => sub {
    my ( $dba, $dba2 ) = @_;
    my $sql = q/select biotype,count(*) from gene 
    join seq_region using (seq_region_id) 
    join coord_system using (coord_system_id) where species_id=/ .
      $dba->species_id().' group by biotype';
    is_same_counts( $dba, $dba2, $sql, 0.75, "Comparing biotype counts" );
    return;
  } );
