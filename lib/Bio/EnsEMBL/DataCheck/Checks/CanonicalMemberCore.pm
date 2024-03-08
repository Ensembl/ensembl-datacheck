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

package Bio::EnsEMBL::DataCheck::Checks::CanonicalMemberCore;

use warnings;
use strict;

use JSON;
use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CanonicalMemberCore',
  DESCRIPTION    => 'Canonical members in compara database match canonical sequences in the core database',
  GROUPS         => ['compara', 'compara_gene_trees', 'core_sync'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['gene_member', 'seq_member'],
  PER_DB         => 1
};

sub skip_tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;

  my $member_count_sql = q/SELECT COUNT(*) FROM gene_member/;
  my $member_count = $dbc->sql_helper->execute_single_result( -SQL => $member_count_sql );
  if ( $member_count == 0 ) {
    return( 1, sprintf("There are no coding gene members in %s", $dbc->dbname) );
  }
}

sub tests {
  my ($self) = @_;

  my $compara_dba = $self->dba;
  my $genome_dba = $compara_dba->get_GenomeDBAdaptor;

  my $compara_sql = q/
    SELECT
      gm.stable_id AS gene_stable_id,
      gm.version AS gene_version,
      sm.stable_id AS seq_stable_id,
      sm.version AS seq_version
    FROM
      gene_member gm
    JOIN
      seq_member sm
    ON
      sm.seq_member_id = gm.canonical_member_id
    WHERE
      gm.genome_db_id = ?
    AND
      biotype_group = 'coding'
  /;

  # This query may fetch some surplus gene-canonical pairs that have not been loaded among
  # the set of Compara gene members for the given genome, but for this test the aim is to
  # ensure we fetch a core gene-canonical pair for each relevant gene member, if available.
  my $core_sql = q/
    SELECT
      g.stable_id AS gene_stable_id,
      g.version AS gene_version,
      tl.stable_id AS seq_stable_id,
      tl.version AS seq_version
    FROM
      coord_system cs
    JOIN
      seq_region sr
    USING
      (coord_system_id)
    JOIN
      gene g
    USING
       (seq_region_id)
    JOIN
      transcript t
    ON
      t.transcript_id = g.canonical_transcript_id
    JOIN
      translation tl
    ON
      tl.translation_id = t.canonical_translation_id
    WHERE
      cs.species_id = ?
    AND
      g.is_current = 1;
  /;

  my $genome_dbs = $genome_dba->fetch_all_current();

  my $desc_1 = "Current genome_dbs exist";
  ok(scalar(@$genome_dbs), $desc_1);

  my $compara_helper = $self->dba->dbc->sql_helper;
  foreach my $genome_db (sort { $a->name cmp $b->name } @$genome_dbs) {
    my $gdb_name = $genome_db->name;

    next if $gdb_name eq 'ancestral_sequences';

    my $core_dba = $self->get_dba($gdb_name, 'core');

    my $desc_2 = "Core database found for $gdb_name";
    next unless ok(defined $core_dba, $desc_2);

    my $compara_results = $compara_helper->execute(
      -SQL => $compara_sql,
      -PARAMS => [$genome_db->dbID],
      -USE_HASHREFS => 1,
    );
    my %compara_canonicals = map { $_->{'gene_stable_id'} => $_ } @$compara_results;

    my $species_id = $core_dba->species_id;
    my $core_results = $core_dba->dbc->sql_helper->execute(
      -SQL => $core_sql,
      -PARAMS => [$species_id],
      -USE_HASHREFS => 1,
    );
    my %core_canonicals = map { $_->{'gene_stable_id'} => $_ } @$core_results;

    my @unknown_gene_stable_ids;
    my @mismatching_gene_versions;
    my @mismatching_canonical_stable_ids;
    my @mismatching_canonical_versions;
    while (my ($gene_stable_id, $compara_gene) = each %compara_canonicals) {

      if (!exists $core_canonicals{$gene_stable_id}) {
        push(@unknown_gene_stable_ids, $gene_stable_id);
        next;

      } else {
        my $compara_gene_version = $compara_gene->{'gene_version'} || undef;

        my $core_gene = $core_canonicals{$gene_stable_id};
        my $core_gene_version = $core_gene->{'gene_version'} || undef;

        if (defined $compara_gene_version || defined $core_gene_version) {
          if ( !(defined $compara_gene_version && defined $core_gene_version)
              || $compara_gene_version != $core_gene_version ) {
            push(@mismatching_gene_versions, [
              $gene_stable_id,
              $compara_gene_version,
              $core_gene_version,
            ]);
            next;

          }
        }

        my $gene_stable_id_ver = $compara_gene_version ? $gene_stable_id . '.' . $compara_gene_version : $gene_stable_id;
        if ($compara_gene->{'seq_stable_id'} ne $core_gene->{'seq_stable_id'}) {
          push(@mismatching_canonical_stable_ids, [
            $gene_stable_id_ver,
            $compara_gene->{'seq_stable_id'},
            $core_gene->{'seq_stable_id'},
          ]);
          next;

        } else {
          my $seq_member_version = $compara_gene->{'seq_version'} || undef;
          my $core_seq_version = $core_gene->{'seq_version'} || undef;

          if (defined $seq_member_version || defined $core_seq_version) {
            if ( !(defined $seq_member_version && defined $core_seq_version)
                || $seq_member_version != $core_seq_version ) {
              push(@mismatching_canonical_versions, [
                $gene_stable_id_ver,
                $compara_gene->{'seq_stable_id'},
                $seq_member_version,
                $core_seq_version,
              ]);
              next;

            }
          }
        }
      }
    }

    my $json = JSON->new();
    $json->space_after(1);

    my $desc_3 = "For all coding genes in $gdb_name, there is a corresponding gene in the core database";
    is(scalar(@unknown_gene_stable_ids), 0, $desc_3)
      || diag explain [sort @unknown_gene_stable_ids];

    my $desc_4 = "All coding genes in $gdb_name have stable ID versions consistent with the core database";
    is(scalar(@mismatching_gene_versions), 0, $desc_4)
      || diag explain [map { $json->utf8->encode($_) } sort { $a->[0] cmp $b->[0] } @mismatching_gene_versions];

    my $desc_5 = "All coding genes in $gdb_name have a canonical translation which is consistent with the core database";
    is(scalar(@mismatching_canonical_stable_ids), 0, $desc_5)
      || diag explain [map { $json->utf8->encode($_) } sort { $a->[0] cmp $b->[0] } @mismatching_canonical_stable_ids];

    my $desc_6 = "All canonical translations in $gdb_name have stable ID versions consistent with the core database";
    is(scalar(@mismatching_canonical_versions), 0, $desc_6)
      || diag explain [map { $json->utf8->encode($_) } sort { $a->[0] cmp $b->[0] } @mismatching_canonical_versions];

    $core_dba->dbc->disconnect_if_idle;
  }
}

1;
