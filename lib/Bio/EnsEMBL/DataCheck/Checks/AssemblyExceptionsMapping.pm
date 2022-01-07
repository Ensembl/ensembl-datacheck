=head1 LICENSE

Copyright [2018-2022] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::AssemblyExceptionsMapping;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'AssemblyExceptionsMapping',
  DESCRIPTION    => 'Assembly exceptions have alignment mappings',
  GROUPS         => ['assembly', 'core', 'brc4_core'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['analysis', 'assembly_exception', 'dna_align_feature',
                     'external_db', 'seq_region',],
  PER_DB         => 1,
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

  my $desc_1 = 'Non-PAR assembly exceptions have "alt_seq_mapping" dna_align_features';
  my $sql_1a = q/
    SELECT DISTINCT sr.name FROM
      seq_region sr INNER JOIN
      assembly_exception ax ON sr.seq_region_id = ax.seq_region_id
    WHERE ax.exc_type <> 'PAR'
  /;
  my $sql_1b = q/
    SELECT DISTINCT sr.name FROM
      seq_region sr INNER JOIN 
      assembly_exception ax ON sr.seq_region_id = ax.seq_region_id INNER JOIN
      dna_align_feature daf ON sr.seq_region_id = daf.seq_region_id INNER JOIN
      analysis a ON daf.analysis_id = a.analysis_id
    WHERE ax.exc_type <> 'PAR' AND a.logic_name = 'alt_seq_mapping'
  /;
  my @all_regions = sort @{$helper->execute_simple(-SQL => $sql_1a)};
  my @alt_seq_regions = sort @{$helper->execute_simple(-SQL => $sql_1b)};
  is_deeply(\@all_regions, \@alt_seq_regions, $desc_1);

  my %alt_seq_regions = map { $_ => 1 } @alt_seq_regions;
  foreach my $name (@all_regions) {
    if (! exists $alt_seq_regions{$name} ) {
      diag("Assembly exception '$name' does not have results in dna_align_feature table for analysis alt_seq_mapping");
    }
  }
}

1;
