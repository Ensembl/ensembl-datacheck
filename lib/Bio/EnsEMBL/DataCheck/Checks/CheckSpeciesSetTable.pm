=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CheckSpeciesSetTable;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckSpeciesSetTable',
  DESCRIPTION    => 'Check species_set_tags have no orphans and species_sets are unique',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_genome_alignments', 'compara_master', 'compara_syntenies', 'compara_references', 'compara_homology_annotation', 'compara_blastocyst'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['species_set']
};

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;
  my $helper = $dbc->sql_helper;
    
  my $sql = q/
    SELECT species_set_id, genome_db_id
    FROM species_set
    ORDER BY genome_db_id
  /;

  my %ss_content;
  my $it = $helper->execute(
    -SQL => $sql,
    -USE_HASHREFS => 1,
    -ITERATOR => 1,
    -PREPARE_PARAMS => [{'mysql_use_result' => 1}],
  );
  $it->each( sub {
      my $row = shift @_;
      $ss_content{ $row->{species_set_id} } .= $row->{genome_db_id} . "-";
    }
  );
  
  my %hasher;
  foreach my $ss_id (keys %ss_content) {
    push @{ $hasher{$ss_content{$ss_id}} }, $ss_id;
  }

  foreach my $content (keys %hasher) {
    my $ex_ss_id = $hasher{$content}->[0];
    my $n_ss = scalar(@{$hasher{$content}});
    my $desc = "Content found in only one species-set: " . join(",", @{$hasher{$content}});
    is($n_ss, 1, $desc);
  }
  
}

1;
