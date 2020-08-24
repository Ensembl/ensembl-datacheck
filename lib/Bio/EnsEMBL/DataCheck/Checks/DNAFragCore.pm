=head1 LICENSE

Copyright [2018-2020] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::DNAFragCore;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'DNAFragCore',
  DESCRIPTION => 'Top-level sequences in the core database match dnafrags in compara database',
  GROUPS      => ['compara', 'compara_master'],
  DB_TYPES    => ['compara'],
  TABLES      => ['dnafrag', 'genome_db']
};

sub tests {
  my ($self) = @_;

  my $dfa = $self->dba->get_DnaFragAdaptor;
  my $gdba = $self->dba->get_GenomeDBAdaptor;

  # We get all the information we need in one hit, the cache
  # will eat up all the memory if we let it...
  $Bio::EnsEMBL::Utils::SeqRegionCache::SEQ_REGION_CACHE_SIZE = 1;

  my $genome_dbs = $gdba->fetch_all_current();

  my $desc = "Current genome_dbs exist";
  ok(scalar(@$genome_dbs), $desc);

  foreach my $genome_db (sort { $a->name cmp $b->name } @$genome_dbs) {
    my $gdb_name = $genome_db->name;

    next if $gdb_name eq 'ancestral_sequences';

    next if defined $genome_db->genome_component;

    my $core_dba = $self->get_dba($genome_db->name, 'core');

    my $desc_1 = "Core database found for $gdb_name";
    next unless ok(defined $core_dba, $desc_1);

    my $sa = $core_dba->get_SliceAdaptor;
    my $slices = $sa->fetch_all('toplevel', undef, 1, 1, 1);

    my $seq_region_count = scalar(@$slices);
    my $dnafrag_count = $dfa->generic_count('genome_db_id = '.$genome_db->dbID);

    my $desc_2 =
      "Equal number of top level seq_regions ($seq_region_count) ".
      "and dnafrags ($dnafrag_count) for $gdb_name";
    is($seq_region_count, $dnafrag_count, $desc_2);

    # If we have lots of regions, it's time consuming to check them
    # all - and if the numbers tally, it's very likely that everything
    # is in sync anyway. Vertebrates take 20 mins with this condition,
    # 6 hours without it.
    if ($seq_region_count > 10000) {
      diag "Too many seq_regions ($seq_region_count) to check individually";
    } else {
      my $desc_3 = "Name matches between all seq_regions and dnafrags for $gdb_name";
      my $desc_4 = "Length matches between all seq_regions and dnafrags for $gdb_name";
      my $desc_5 = "Reference status matches between all seq_region and dnafrag for $gdb_name";

      my @name_mismatches   = ();
      my @length_mismatches = ();
      my @is_ref_mismatches = ();

      foreach my $slice (@$slices) {
        my $slice_name = $slice->coord_system_name.':'.$slice->seq_region_name;

        my $dnafrag = $dfa->fetch_by_GenomeDB_and_name($genome_db, $slice->seq_region_name);
        if (! defined $dnafrag) {
          push @name_mismatches, $slice_name;
        } else {
          if ($slice->seq_region_length != $dnafrag->length) {
            push @length_mismatches, $slice_name;
          }
          if ($slice->is_reference != $dnafrag->is_reference) {
            push @is_ref_mismatches, $slice_name;
          }
        }
      }

      is(scalar(@name_mismatches),   0, $desc_3) || diag explain \@name_mismatches;
      is(scalar(@length_mismatches), 0, $desc_4) || diag explain \@length_mismatches;
      is(scalar(@is_ref_mismatches), 0, $desc_5) || diag explain \@is_ref_mismatches;
    }
  }
}

1;
