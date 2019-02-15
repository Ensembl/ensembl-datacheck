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

package Bio::EnsEMBL::DataCheck::Checks::ForeignKeysMultiDB;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count array_diff hash_diff/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ForeignKeysMultiDB',
  DESCRIPTION => 'Foreign key relationships between tables from different databases are not violated',
  GROUPS      => ['funcgen', 'schema', 'variation'],
  DB_TYPES    => ['funcgen', 'variation']
};

sub tests {
  my ($self) = @_;

  if ($self->dba->group eq 'variation') {
    $self->variation_core_fk();
    $self->variation_funcgen_fk();
  } elsif ($self->dba->group eq 'funcgen') {
    $self->funcgen_core_fk();
  }
}

sub variation_core_fk {
  my ($self) = @_;
  # Core <-> Variation database relationships. We cannot assume that the dbs
  # are on the same server, so need to compare in Perl rather than SQL.

  my $dna_dba = $self->get_dna_dba();

  my ($stable_ids) = $self->col_array($dna_dba, 'transcript', 'stable_id');
  my @stable_id_tables = qw/
    transcript_variation
  /;
  foreach my $table (@stable_id_tables) {
    my $desc = "All stable IDs in $table exist in core database";

    my ($ids, $label) = $self->col_array($self->dba, $table, 'feature_stable_id');
    my $diff = array_diff($ids, $stable_ids, $label);
    my @diffs = @{$$diff{"In $label only"}};
    is(scalar(@diffs), 0, $desc) || diag explain \@diffs;
  }

  my ($seq_region_ids) = $self->col_array($dna_dba, 'seq_region', 'seq_region_id');
  my @seq_region_id_tables = qw/
    variation_feature
    structural_variation_feature
  /;
  foreach my $table (@seq_region_id_tables) {
    my $desc = "All seq_region IDs in $table exist in core database";

    my ($ids, $label) = $self->col_array($self->dba, $table, 'seq_region_id');
    my $diff = array_diff($ids, $seq_region_ids, $label);
    my @diffs = @{$$diff{"In $label only"}};
    is(scalar(@diffs), 0, $desc) || diag explain \@diffs;
  }

  {
    my $desc = "seq_region IDs and names are consistent with the core database";
    my ($sr_variation, $label) = $self->col_hash($self->dba, 'seq_region', 'seq_region_id', 'name');
    my ($sr_core) = $self->col_hash($dna_dba, 'seq_region', 'seq_region_id', 'name');
    my $diff = hash_diff($sr_variation, $sr_core, $label);
    my @diffs = keys %{$$diff{"In $label only"}};
    is(scalar(@diffs), 0, $desc) || diag explain \@diffs;
    @diffs = keys %{$$diff{"Different values"}};
    is(scalar(@diffs), 0, $desc) || diag explain \@diffs;
  }
}

sub variation_funcgen_fk {
  my ($self) = @_;
  # Funcgen <-> Variation database relationships. We cannot assume that the dbs
  # are on the same server, so need to compare in Perl rather than SQL.

  SKIP: {
    my $funcgen_dba = $self->get_dba(undef, 'funcgen');
    skip 'No funcgen database', 1 unless defined $funcgen_dba;

    my $sql = 'SELECT COUNT(name) FROM regulatory_build WHERE is_current = 1';
    skip 'The database has no regulatory build', 1 unless sql_count($funcgen_dba, $sql);

    {
      my $desc = "All stable IDs in motif_feature_variation exist in funcgen database";
      my ($mf_ids) = $self->col_array($funcgen_dba, 'motif_feature', 'stable_id');
      my ($mfv_ids, $label) = $self->col_array($self->dba, 'motif_feature_variation', 'feature_stable_id');
      my $diff = array_diff($mfv_ids, $mf_ids, $label);
      my @diffs = @{$$diff{"In $label only"}};
      is(scalar(@diffs), 0, $desc);
    }

    {
      my $desc = "All stable IDs in regulatory_feature_variation exist in funcgen database";
      my ($rf_ids) = $self->col_array($funcgen_dba, 'regulatory_feature', 'stable_id');
      my ($rfv_ids, $label) = $self->col_array($self->dba, 'regulatory_feature_variation', 'feature_stable_id');
      my $diff = array_diff($rfv_ids, $rf_ids, $label);
      my @diffs = @{$$diff{"In $label only"}};
      is(scalar(@diffs), 0, $desc);
    }
  }
}

sub funcgen_core_fk {
  my ($self) = @_;
  # Core <-> Funcgen database relationships. We cannot assume that the dbs
  # are on the same server, so need to compare in Perl rather than SQL.

  my $dna_dba = $self->get_dna_dba();

  my ($stable_ids) = $self->col_array($dna_dba, 'transcript', 'stable_id');
  my @stable_id_tables = qw/
    probe_feature_transcript
    probe_set_transcript
    probe_transcript
  /;
  foreach my $table (@stable_id_tables) {
    my $desc = "All stable IDs in $table exist in core database";

    my ($ids, $label) = $self->col_array($self->dba, $table, 'stable_id');
    my $diff = array_diff($ids, $stable_ids, $label);
    my @diffs = @{$$diff{"In $label only"}};
    is(scalar(@diffs), 0, $desc) || diag explain \@diffs;
  }

  my ($seq_region_ids) = $self->col_array($dna_dba, 'seq_region', 'seq_region_id');
  my @seq_region_id_tables = qw/
    external_feature
    mirna_target_feature
    motif_feature
    peak
    probe_feature
    regulatory_feature
  /;
  foreach my $table (@seq_region_id_tables) {
    my $desc = "All seq_region IDs in $table exist in core database";

    my ($ids, $label) = $self->col_array($self->dba, $table, 'seq_region_id');
    my $diff = array_diff($ids, $seq_region_ids, $label);
    my @diffs = @{$$diff{"In $label only"}};
    is(scalar(@diffs), 0, $desc) || diag explain \@diffs;
  }
}

sub col_array {
  my ($self, $dba, $table, $col) =  @_;

  my $dbname = $dba->dbc->dbname();
  my $label  = "$dbname.$table.$col";

  my $sql  = "SELECT DISTINCT $col FROM $table WHERE $col IS NOT NULL";
  my $data = $dba->dbc->sql_helper()->execute_simple( -SQL => $sql );

  return ($data, $label);
}

sub col_hash {
  my ($self, $dba, $table, $col1, $col2) =  @_;

  my $dbname = $dba->dbc->dbname();
  my $label  = "$dbname.$table.[$col1,$col2]";

  my $sql  = "SELECT DISTINCT $col1, $col2 FROM $table WHERE $col1 IS NOT NULL";
  my $data = $dba->dbc->sql_helper()->execute_into_hash( -SQL => $sql );

  return ($data, $label);
}

1;
