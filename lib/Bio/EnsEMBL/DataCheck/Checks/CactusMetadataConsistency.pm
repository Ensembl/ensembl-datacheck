=head1 LICENSE

Copyright [2018-2025] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CactusMetadataConsistency;

use warnings;
use strict;

use Moose;
use Test::More;

use Bio::EnsEMBL::Hive::Utils qw/destringify/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CactusMetadataConsistency',
  DESCRIPTION    => 'Each Cactus alignment has consistent metadata',
  GROUPS         => ['compara', 'compara_genome_alignments'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['genome_db', 'method_link', 'method_link_species_set', 'method_link_species_set_tag',
                     'species_tree_node', 'species_tree_root']
};

sub tests {
  my ($self) = @_;

  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my $gdb_adap = $self->dba->get_GenomeDBAdaptor;

  my $cactus_mlsses = [];
  foreach my $method_type ('CACTUS_DB', 'CACTUS_HAL') {
    my $cactus_mlsses_of_type = $mlss_adap->fetch_all_by_method_link_type($method_type);
    push(@{$cactus_mlsses}, @{$cactus_mlsses_of_type});
  }

  unless (scalar(@{$cactus_mlsses})) {
    plan skip_all => "No Cactus MLSSes in this database";
  }

  foreach my $mlss (@{$cactus_mlsses}) {

    my $species_map = destringify($mlss->get_value_for_tag('HAL_mapping', '{}'));
    my @hal_gdb_ids = keys %{$species_map};

    my $mlss_name = $mlss->name;
    my $mlss_id = $mlss->dbID;

    my $desc_1 = "HAL mapping data found for $mlss_name ($mlss_id)";
    ok(scalar(@hal_gdb_ids) > 0, $desc_1);

    my $mlss_sp_tree = $mlss->species_tree;
    my $desc_2 = "Species tree found for $mlss_name ($mlss_id)";
    isnt($mlss_sp_tree, undef, $desc_2);

    foreach my $hal_gdb_id (@hal_gdb_ids) {
      my $hal_gdb = $gdb_adap->fetch_by_dbID($hal_gdb_id);

      my $desc_3 = "$mlss_name HAL mapping GenomeDB (genome_db_id:$hal_gdb_id) is present";
      isnt($hal_gdb, undef, $desc_3);

      my $desc_4 = "$mlss_name HAL mapping GenomeDB (genome_db_id:$hal_gdb_id) is current";
      ok(defined $hal_gdb && $hal_gdb->is_current, $desc_4);

      my $desc_5 = "$mlss_name HAL mapping GenomeDB (genome_db_id:$hal_gdb_id) is in species tree";
      my %mlss_sp_tree_gdb_ids = map { $_ => 1 } keys %{$mlss_sp_tree->get_genome_db_id_2_node_hash()};
      ok(exists $mlss_sp_tree_gdb_ids{$hal_gdb_id}, $desc_5);
    }
  }
}

1;
