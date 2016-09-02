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
use Bio::EnsEMBL::DataTest::Utils::DBUtils qw/rowcount is_rowcount_nonzero is_rowcount_zero/;
use Data::Dumper;

Bio::EnsEMBL::DataTest::TableAwareTest->new(
  name     => 'assembly_exceptions',
  description =>
    q/Check if assembly_exceptions are present and correct/
  ,
  db_types => ['core'],
  tables   => [
              'seq_region', 'assembly_exception',
              'seq_region', 'dna_align_feature',
              'analysis',   'external_db' ],
  test => sub {
    my ($dba) = @_;

    is_rowcount_zero(
      $dba,
q/SELECT COUNT(*) FROM assembly_exception WHERE seq_region_start > seq_region_end/,
'Test if assembly_exception has rows where seq_region_start > seq_region_end' );

    is_rowcount_zero(
      $dba,
q/SELECT COUNT(*) FROM assembly_exception WHERE exc_seq_region_start > exc_seq_region_end/,
'Test if assembly_exception has rows where exc_seq_region_start > exc_seq_region_end'
    );
    if (
       rowcount( $dba->dbc(),
               q/SELECT COUNT(*) FROM assembly_exception WHERE exc_type="HAP"/ )
       > 0 )
    {
      is_rowcount_nonzero(
        $dba,
q/SELECT COUNT(*) FROM seq_region_attrib sra, attrib_type at WHERE sra.attrib_type_id=at.attrib_type_id AND at.code="non_ref"/,
'Test if assembly_exception contains at least one exception of type "HAP" but there are no seq_region_attrib rows of type "non-reference"'
      );
    }

    my %dafs = map { $_ => 1 } @{
      $dba->dbc()->sql_helper()->execute_simple(
        -SQL =>
q/SELECT distinct sr.name FROM seq_region sr, assembly_exception ax, dna_align_feature daf, analysis a 
      WHERE sr.seq_region_id = ax.seq_region_id AND exc_type not in ('PAR') AND sr.seq_region_id = daf.seq_region_id 
      AND daf.analysis_id = a.analysis_id AND a.logic_name = 'alt_seq_mapping'/
      ) };

    for my $name (
      @{$dba->dbc()->sql_helper()->execute_simple(
          -SQL =>
            q/SELECT distinct sr.name FROM seq_region sr, assembly_exception ax 
where ax.seq_region_id = sr.seq_region_id and exc_type not in ('PAR')/
        ) } )
    {
      if ( !$dafs{$name} ) {
        fail(
"Assembly exception '$name' does not have results in dna_align_feature table for analysis alt_seq_mapping"
        );
      }
    }

    is_rowcount_zero(
      $dba,
q/SELECT count(distinct sr.name) FROM seq_region sr, assembly_exception ax, seq_region sr2,  dna_align_feature daf, analysis a 
        WHERE a.analysis_id = daf.analysis_id AND  daf.seq_region_id = sr.seq_region_id AND ax.seq_region_id = sr.seq_region_id 
        AND ax.exc_seq_region_id = sr2.seq_region_id AND logic_name = 'alt_seq_mapping' AND  exc_type not in ('PAR') AND sr2.name != hit_name/,
      'Test for assembly exceptions mapping to more than one reference region'
    );

    is_rowcount_zero(
      $dba,
q/SELECT count(distinct sr.name) FROM seq_region sr, assembly_exception ax, external_db e, 
                        dna_align_feature daf, analysis a WHERE a.analysis_id = daf.analysis_id AND 
                        daf.seq_region_id = sr.seq_region_id AND ax.seq_region_id = sr.seq_region_id AND 
                        e.external_db_id = daf.external_db_id AND logic_name = 'alt_seq_mapping' AND 
                        exc_type not in ('PAR') AND e.db_name != 'GRC_primary_assembly'/
      ,
'Test for assembly exceptions with mapping not from "GRC_primary_assembly"' );

    return;
  } );
