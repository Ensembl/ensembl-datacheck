=head1 LICENSE

Copyright [2018-2019] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::AssemblyExceptions;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'AssemblyExceptions',
  DESCRIPTION => 'Assembly exceptions are correctly configured',
  GROUPS      => ['assembly', 'core'],
  DB_TYPES    => ['core'],
  TABLES      => ['analysis', 'assembly_exception', 'dna_align_feature',
                  'external_db', 'seq_region',],
  PER_DB      => 1,
};

sub skip_tests {
  my ($self) = @_;

  my $sql = 'SELECT COUNT(*) FROM assembly_exception';

  if (! sql_count($self->dba, $sql) ) {
    return (1, 'No assembly exceptions.');
  }
}

sub tests {
  my ($self) = @_;
  my $dba = $self->dba;
  my $helper = $dba->dbc->sql_helper;

  my $desc_1 = 'assembly_exception: seq_region_start > seq_region_end';
  my $sql_1  = q/
    SELECT COUNT(*) FROM assembly_exception
    WHERE seq_region_start > seq_region_end
  /;
  is_rows_zero($dba, $sql_1, $desc_1);

  my $desc_2 = 'assembly_exception: exc_seq_region_start > exc_seq_region_end';
  my $sql_2  = q/
    SELECT COUNT(*) FROM assembly_exception
    WHERE exc_seq_region_start > exc_seq_region_end
  /;
  is_rows_zero($dba, $sql_2, $desc_2);

  my $desc_3 = 'if assembly_exception contains exception of type "HAP", '.
    'then there are seq_region_attrib rows with type "non-reference"';
  my $sql_3a = q/
    SELECT COUNT(*) FROM assembly_exception WHERE exc_type = "HAP"
  /;
  my $sql_3b = q/
    SELECT COUNT(*) FROM
      seq_region_attrib INNER JOIN
      attrib_type USING (attrib_type_id)
    WHERE code = "non_ref"
  /;
  if (sql_count($dba, $sql_3a)) {
    is_rows_nonzero($dba, $sql_3b, $desc_3);
  }

  my $desc_4 = 'Non-PAR assembly exceptions have "alt_seq_mapping" dna_align_features';
  my $sql_4a = q/
    SELECT DISTINCT sr.name FROM
      seq_region sr INNER JOIN
      assembly_exception ax ON sr.seq_region_id = ax.seq_region_id
    WHERE ax.exc_type <> 'PAR'
  /;
  my $sql_4b = q/
    SELECT DISTINCT sr.name FROM
      seq_region sr INNER JOIN 
      assembly_exception ax ON sr.seq_region_id = ax.seq_region_id INNER JOIN
      dna_align_feature daf ON sr.seq_region_id = daf.seq_region_id INNER JOIN
      analysis a ON daf.analysis_id = a.analysis_id
    WHERE ax.exc_type <> 'PAR' AND a.logic_name = 'alt_seq_mapping'
  /;
  my @all_regions = sort @{$helper->execute_simple(-SQL => $sql_4a)};
  my @alt_seq_regions = sort @{$helper->execute_simple(-SQL => $sql_4b)};
  is_deeply(\@all_regions, \@alt_seq_regions, $desc_4);

  my %all_regions = map { $_ => 1 } @all_regions;
  foreach my $name (@alt_seq_regions) {
    if (! exists $all_regions{$name} ) {
      diag("Assembly exception '$name' does not have results in dna_align_feature table for analysis alt_seq_mapping");
    }
  }

  my $desc_5 = 'Assembly exceptions map to just one reference region';
  my $sql_5  = q/
    SELECT COUNT(DISTINCT sr.name) FROM
      seq_region sr INNER JOIN
      assembly_exception ax ON sr.seq_region_id = ax.seq_region_id INNER JOIN
      seq_region sr2 ON ax.exc_seq_region_id = sr2.seq_region_id INNER JOIN
      dna_align_feature daf ON sr.seq_region_id = daf.seq_region_id INNER JOIN
      analysis a ON daf.analysis_id = a.analysis_id
    WHERE ax.exc_type <> 'PAR' AND a.logic_name = 'alt_seq_mapping' AND sr2.name <> daf.hit_name
  /;
  is_rows_zero($dba, $sql_5, $desc_5);

  my $desc_6 = 'Assembly exceptions only have mappings for "GRC_primary_assembly"';
  my $sql_6  = q/
    SELECT COUNT(DISTINCT sr.name) FROM
      seq_region sr INNER JOIN
      assembly_exception ax ON sr.seq_region_id = ax.seq_region_id INNER JOIN
      dna_align_feature daf ON sr.seq_region_id = daf.seq_region_id INNER JOIN
      analysis a ON daf.analysis_id = a.analysis_id INNER JOIN
      external_db e ON daf.external_db_id = e.external_db_id
    WHERE ax.exc_type <> 'PAR' AND a.logic_name = 'alt_seq_mapping' AND e.db_name <> 'GRC_primary_assembly'
  /;
  is_rows_zero($dba, $sql_6, $desc_6);
}

1;
