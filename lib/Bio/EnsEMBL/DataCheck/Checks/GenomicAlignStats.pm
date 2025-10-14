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

package Bio::EnsEMBL::DataCheck::Checks::GenomicAlignStats;

use warnings;
use strict;

use Moose;
use Test::More;

use Bio::EnsEMBL::Compara::Utils::Stats qw(get_coding_exon_regions);

use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'GenomicAlignStats',
  DESCRIPTION    => 'Check consistency of genomic alignment stats',
  GROUPS         => ['compara', 'compara_genome_alignments'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => [
    'dnafrag',
    'genome_db',
    'genomic_align_block',
    'method_link',
    'method_link_species_set',
    'method_link_species_set_tag',
    'species_set',
    'species_set_header',
    'species_tree_node',
    'species_tree_node_tag',
  ],
};

sub skip_tests {
    my ($self) = @_;
    my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
    my @method_types = qw (CACTUS_DB EPO EPO_EXTENDED LASTZ_NET LASTZ_PATCH PECAN POLYPLOID);
    my $db_name = $self->dba->dbc->dbname;

    my @mlsses;
    foreach my $method_type ( @method_types ) {
      my $mlsses_of_type = $mlss_adap->fetch_all_by_method_link_type($method_type);
      push @mlsses, @{$mlsses_of_type};
    }

    if ( scalar(@mlsses) == 0 ) {
      return( 1, "There are no genomic alignments in $db_name" );
    }
}

sub tests {
  my ($self) = @_;
  my $dba = $self->dba;
  my $helper = $dba->dbc->sql_helper;
  my $mlss_adap = $dba->get_MethodLinkSpeciesSetAdaptor;
  my @method_types = qw (CACTUS_DB EPO EPO_EXTENDED LASTZ_NET LASTZ_PATCH PECAN POLYPLOID);

  my %gdbs_by_id;
  my %mlsses_by_id;
  foreach my $method_type ( @method_types ) {
    my $mlsses_of_type = $mlss_adap->fetch_all_by_method_link_type($method_type);
    foreach my $mlss (@{$mlsses_of_type}) {
      $mlsses_by_id{$mlss->dbID} = $mlss;

      foreach my $gdb (@{$mlss->species_set->genome_dbs}) {
        $gdbs_by_id{$gdb->dbID} = $gdb;
      }
    }
  }

  my $total_genome_length_sql = q/
    SELECT SUM(length)
    FROM dnafrag
    WHERE is_reference = 1
    AND genome_db_id = ?
  /;

  my %obs_genome_lengths;
  my %obs_coding_exon_lengths;
  while (my ($gdb_id, $gdb) = each %gdbs_by_id) {

    $obs_genome_lengths{$gdb_id} = $helper->execute_single_result( -SQL => $total_genome_length_sql, -PARAMS => [$gdb_id] );

    my $coding_exon_length = 0;
    my $species_dba = $self->get_dba($gdb->name, 'core');
    $species_dba->dbc->prevent_disconnect( sub {
      my $slices_it = Bio::EnsEMBL::Compara::Utils::CoreDBAdaptor::iterate_toplevel_slices($species_dba);
      while (my $slice = $slices_it->next()) {
        my $coding_exons = get_coding_exon_regions($slice);
        foreach my $coding_exon (@{$coding_exons}) {
          my ($start, $end) = @{$coding_exon};
          $coding_exon_length += ($end - $start + 1);
        }
      }
    } );
    $obs_coding_exon_lengths{$gdb_id} = $coding_exon_length;
  }

  my $block_count_tag_sql = q/
    SELECT value
    FROM method_link_species_set_tag
    WHERE method_link_species_set_id = ?
    AND tag = 'num_blocks'
  /;

  my %exp_block_counts;
  my %exp_genome_lengths;
  my %exp_coding_exon_lengths;
  foreach my $mlss_id ( sort keys %mlsses_by_id ) {
    my $mlss = $mlsses_by_id{$mlss_id};
    my $results = $helper->execute_simple( -SQL => $block_count_tag_sql, -PARAMS => [$mlss_id] );

    if (scalar(@{$results}) == 1) {
      my $block_count_tag = $results->[0];
      my $exp_block_count = $mlss->method->type eq 'EPO'
                          ? 2 * $block_count_tag
                          : $block_count_tag
                          ;

      $exp_block_counts{$mlss_id} = $exp_block_count;
    }

    if ($mlss->species_set->size > 2) {

      my $gdb_id_2_node_hash = $mlss->species_tree && $mlss->species_tree->get_genome_db_id_2_node_hash;
      foreach my $genome_db (@{$mlss->species_set->genome_dbs}) {
        my $gdb_id = $genome_db->dbID;
        my @gdb_tags = qw(genome_length coding_exon_length);
        my %gdb_stats;
        foreach my $tag (@gdb_tags) {
          if ($gdb_id_2_node_hash
              && exists $gdb_id_2_node_hash->{$gdb_id}
              && $gdb_id_2_node_hash->{$gdb_id}->has_tag($tag)) {
            $gdb_stats{$tag} = $gdb_id_2_node_hash->{$gdb_id}->get_value_for_tag($tag);
          } elsif (defined $mlss->has_tag("${tag}_${gdb_id}")) {
            $gdb_stats{$tag} = $mlss->get_value_for_tag("${tag}_${gdb_id}");
          }
        }

        $exp_coding_exon_lengths{$mlss_id}{$gdb_id} = $gdb_stats{'coding_exon_length'} if (exists $gdb_stats{'coding_exon_length'});
        $exp_genome_lengths{$mlss_id}{$gdb_id} = $gdb_stats{'genome_length'} if (exists $gdb_stats{'genome_length'});
      }

    } else {
      my ($ref_gdb, $non_ref_gdb) = $mlss->find_pairwise_reference();

      my %non_ref_stats = map { $_ => $mlss->get_value_for_tag($_) } ('non_ref_coding_exon_length', 'non_ref_genome_length');
      $exp_coding_exon_lengths{$mlss_id}{$non_ref_gdb->dbID} = $non_ref_stats{'non_ref_coding_exon_length'} if (exists $non_ref_stats{'non_ref_coding_exon_length'});
      $exp_genome_lengths{$mlss_id}{$non_ref_gdb->dbID} = $non_ref_stats{'non_ref_genome_length'} if (exists $non_ref_stats{'non_ref_genome_length'});

      my %ref_stats = map { $_ => $mlss->get_value_for_tag($_) } ('ref_coding_exon_length', 'ref_genome_length');
      $exp_coding_exon_lengths{$mlss_id}{$ref_gdb->dbID} = $ref_stats{'ref_coding_exon_length'} if (exists $ref_stats{'ref_coding_exon_length'});
      $exp_genome_lengths{$mlss_id}{$ref_gdb->dbID} = $ref_stats{'ref_genome_length'} if (exists $ref_stats{'ref_genome_length'});
    }
  }

  my $gab_count_sql = q/
    SELECT COUNT(*)
    FROM genomic_align_block
    WHERE method_link_species_set_id = ?
  /;

  foreach my $mlss_id ( sort keys %exp_block_counts ) {
    my $results = $helper->execute_simple( -SQL => $gab_count_sql, -PARAMS => [$mlss_id] );
    my $obs_block_count = $results->[0];
    my $exp_block_count = $exp_block_counts{$mlss_id};
    my $mlss_name = $mlsses_by_id{$mlss_id}->name;
    is($obs_block_count, $exp_block_count, "$mlss_name (mlss_id:$mlss_id) block count consistency");
  }

  foreach my $mlss_id ( sort keys %exp_genome_lengths ) {
    my $mlss_name = $mlsses_by_id{$mlss_id}->name;
    foreach my $gdb_id (sort keys %{$exp_genome_lengths{$mlss_id}} ) {
      my $gdb_name = $gdbs_by_id{$gdb_id}->name;
      my $exp_genome_length = $exp_genome_lengths{$mlss_id}{$gdb_id};
      my $obs_genome_length = $obs_genome_lengths{$gdb_id};
      is($obs_genome_length, $exp_genome_length, "genome length consistency of $gdb_name in MLSS '$mlss_name' (mlss_id:$mlss_id)");
    }
  }

  foreach my $mlss_id ( sort keys %exp_coding_exon_lengths ) {
    my $mlss_name = $mlsses_by_id{$mlss_id}->name;
    foreach my $gdb_id (sort keys %{$exp_coding_exon_lengths{$mlss_id}} ) {
      my $gdb_name = $gdbs_by_id{$gdb_id}->name;
      my $exp_coding_exon_length = $exp_coding_exon_lengths{$mlss_id}{$gdb_id};
      my $obs_coding_exon_length = $obs_coding_exon_lengths{$gdb_id};
      is($obs_coding_exon_length, $exp_coding_exon_length, "coding exon length consistency of $gdb_name in MLSS '$mlss_name' (mlss_id:$mlss_id)");
    }
  }
}

1;
