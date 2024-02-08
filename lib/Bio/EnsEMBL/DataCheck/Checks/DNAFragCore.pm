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

package Bio::EnsEMBL::DataCheck::Checks::DNAFragCore;

use warnings;
use strict;

use Moose;
use Test::More;

use Bio::EnsEMBL::Compara::DnaFrag;
use Bio::EnsEMBL::Compara::Utils::CoreDBAdaptor;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'DNAFragCore',
  DESCRIPTION => 'Top-level sequences in the core database match dnafrags in compara database',
  GROUPS      => ['compara', 'compara_gene_trees', 'compara_genome_alignments', 'compara_master', 'compara_syntenies', 'core_sync'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES    => ['compara'],
  TABLES      => ['dnafrag', 'genome_db']
};

sub tests {
  my ($self) = @_;

  my $dfa = $self->dba->get_DnaFragAdaptor;
  my $gdba = $self->dba->get_GenomeDBAdaptor;

  my $genome_dbs = $gdba->fetch_all_current();

  my $desc = "Current genome_dbs exist";
  ok(scalar(@$genome_dbs), $desc);

  foreach my $genome_db (sort { $a->name cmp $b->name } @$genome_dbs) {
    my $gdb_name = $genome_db->name;

    next if $gdb_name eq 'ancestral_sequences';

    my $core_dba = $self->get_dba($genome_db->name, 'core');

    my $desc_1 = "Core database found for $gdb_name";
    next unless ok(defined $core_dba, $desc_1);

    # We want batches in order to load the DnaFrags more efficiently
    my $it = Bio::EnsEMBL::Compara::Utils::CoreDBAdaptor::iterate_toplevel_slices($core_dba, $genome_db->genome_component, -RETURN_BATCHES => 1);

    my $seq_region_count = 0;
    my $dnafrag_count = $dfa->generic_count('genome_db_id = '.$genome_db->dbID);

    my $desc_3 = "Name matches between all seq_regions and dnafrags for $gdb_name";
    my $desc_4 = "Length matches between all seq_regions and dnafrags for $gdb_name";
    my $desc_5 = "Reference status matches between all seq_region and dnafrag for $gdb_name";
    my $desc_6 = "Codon table matches between all seq_region and dnafrag for $gdb_name";
    my $desc_7 = "Cellular component matches between all seq_region and dnafrag for $gdb_name";
    my $desc_8 = "Coordinate system matches between all seq_region and dnafrag for $gdb_name";

    my @name_mismatches   = ();
    my @length_mismatches = ();
    my @is_ref_mismatches = ();
    my @codon_mismatches  = ();
    my @cell_mismatches   = ();
    my @coord_mismatches  = ();

    # The iterator returns batches of slices
    while (my $slices = $it->next()) {

      # Fetch the corresponding dnafrags
      my @slice_names = map {$_->seq_region_name} @$slices;
      my $dnafrags = $dfa->fetch_all_by_GenomeDB_and_names($genome_db, \@slice_names);
      my %dnafrag_hash = map {$_->name => $_} @$dnafrags;

      # Iterate over the slices
      foreach my $slice (@$slices) {
        $seq_region_count++;
        my $slice_name = $slice->coord_system_name.':'.$slice->seq_region_name;

        # Let the Compara API build the object as it should be
        my $expected_dnafrag = Bio::EnsEMBL::Compara::DnaFrag->new_from_Slice($slice, $genome_db);
        # And find the one we have in the database
        my $dnafrag = $dnafrag_hash{$expected_dnafrag->name};

        if (! defined $dnafrag) {
          push @name_mismatches, $slice_name;

        } else {

          # And compare all the attributes one by one
          if ($expected_dnafrag->length != $dnafrag->length) {
            push @length_mismatches, [$slice_name, $expected_dnafrag->length, $dnafrag->length];
          }
          if ($expected_dnafrag->is_reference != $dnafrag->is_reference) {
            push @is_ref_mismatches, [$slice_name, $expected_dnafrag->is_reference, $dnafrag->is_reference];
          }
          if ($expected_dnafrag->codon_table_id != $dnafrag->codon_table_id) {
            push @codon_mismatches, [$slice_name, $expected_dnafrag->codon_table_id, $dnafrag->codon_table_id];
          }
          if ($expected_dnafrag->cellular_component ne $dnafrag->cellular_component) {
            push @cell_mismatches, [$slice_name, $slice->{'attributes'}->{'sequence_location'}, $expected_dnafrag->cellular_component, $dnafrag->cellular_component];
          }
          if ($expected_dnafrag->coord_system_name ne $dnafrag->coord_system_name) {
            push @coord_mismatches, [$slice_name, $expected_dnafrag->coord_system_name, $dnafrag->coord_system_name];
          }
        }
      }
    }

    my $desc_2 =
      "Equal number of top level seq_regions ($seq_region_count) ".
      "and dnafrags ($dnafrag_count) for $gdb_name";
    is($seq_region_count, $dnafrag_count, $desc_2);

    is(scalar(@name_mismatches),   0, $desc_3) || diag explain \@name_mismatches;
    is(scalar(@length_mismatches), 0, $desc_4) || diag explain \@length_mismatches;
    is(scalar(@is_ref_mismatches), 0, $desc_5) || diag explain \@is_ref_mismatches;
    is(scalar(@codon_mismatches),  0, $desc_6) || diag explain \@codon_mismatches;
    is(scalar(@cell_mismatches),   0, $desc_7) || diag explain \@cell_mismatches;
    is(scalar(@coord_mismatches),  0, $desc_8) || diag explain \@coord_mismatches;
    $core_dba->dbc->disconnect_if_idle;
  }
}

1;
