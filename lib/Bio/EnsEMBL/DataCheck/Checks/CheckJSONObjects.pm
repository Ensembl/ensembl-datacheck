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

package Bio::EnsEMBL::DataCheck::Checks::CheckJSONObjects;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use JSON qw(decode_json);

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckJSONObjects',
  DESCRIPTION    => 'Check that all JSON objects in gene_tree_object_store are valid',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_gene_tree_pipelines'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['gene_tree_object_store']
};

sub tests {
  my ($self) = @_;
  my $helper = $self->dba->dbc->sql_helper;
  my @data_labels = qw( exon_boundaries cafe cafe_lca consensus_cigar_line );
  my $sql_1 = qq/
    SELECT root_id, data_label, UNCOMPRESS(compressed_data) AS json_string 
      FROM gene_tree_object_store
    WHERE data_label = ?
  /;

  foreach my $data_label ( @data_labels ) {
    my @bad_root_id;
    my $it = $helper->execute(
      -SQL => $sql_1,
      -PARAMS => [$data_label],
      -USE_HASHREFS => 1,
      -ITERATOR => 1,
      -PREPARE_PARAMS => [{'mysql_use_result' => 1}],
    );
    $it->each( sub {
        my $row = shift @_;
        my $json_check = eval{ decode_json($row->{json_string}) };
        if ( $@ ) {
          push @bad_root_id, $row->{root_id};
        }
      }
    );

    my $desc = "JSON objects are valid for all root_ids with data_label $data_label";
    is( scalar(@bad_root_id), 0, $desc ) || diag explain @bad_root_id;
  }

}

1;

