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

package Bio::EnsEMBL::DataCheck::Checks::MetaCoord;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MetaCoord',
  DESCRIPTION => 'The meta_coord table is correctly populated',
  GROUPS      => ['annotation', 'core', 'corelike', 'funcgen', 'geneset', 'protein_features', 'variation'],
  DB_TYPES    => ['cdna', 'core', 'funcgen', 'otherfeatures', 'rnaseq', 'variation'],
};

sub tests {
  my ($self) = @_;
  my $helper = $self->dba->dbc->sql_helper;

  my $meta_coord_lengths = $self->meta_coord_lengths($helper);
  my $feature_lengths    = $self->feature_lengths($helper);

  my $desc = 'Contents of meta_coord table are correct';
  my $pass = is_deeply($meta_coord_lengths, $feature_lengths, $desc);
  if (!$pass) {
    diag explain $meta_coord_lengths;
    diag explain $feature_lengths;
  }
}

sub meta_coord_lengths {
  my ($self, $helper) = @_;

  my $sql;
  if ($self->dba->group =~ /(funcgen|variation)/) {
    $sql = 'SELECT table_name, coord_system_id, max_length FROM meta_coord';
  } else {
    my $species_id = $self->dba->species_id;
    $sql = qq/
      SELECT table_name, coord_system_id, max_length
      FROM meta_coord INNER JOIN coord_system USING (coord_system_id)
      WHERE species_id = $species_id;
    /;
  }

  my $meta_coord_lengths = $helper->execute(-SQL => $sql);

  my %meta_coord_lengths;
  foreach (@$meta_coord_lengths) {
    $meta_coord_lengths{$_->[0]}{$_->[1]} = $_->[2];
  }

  return \%meta_coord_lengths;
}

sub feature_lengths {
  my ($self, $helper) = @_;

  if ($self->dba->group =~ /(funcgen|variation)/) {
    return $self->feature_lengths_dnadb($helper);
  } else {
    return $self->feature_lengths_core($helper);
  }
}

sub feature_lengths_core {
  my ($self, $helper) = @_;
  my $species_id = $self->dba->species_id;

  my @tables = $self->feature_tables;

  my @sqls;
  foreach my $table (sort @tables) {
    my $sql = qq/
      SELECT
        '$table' AS table_name,
        coord_system_id,
        MAX(CAST(seq_region_end AS SIGNED) - CAST(seq_region_start AS SIGNED)) + 1 AS max_length
      FROM
        $table INNER JOIN
        seq_region USING (seq_region_id) INNER JOIN
        coord_system USING (coord_system_id)
      WHERE
        species_id = $species_id
      GROUP BY
        coord_system_id
    /;
    push @sqls, $sql;
  }

  my $union_sql = join(' UNION ', @sqls);
  my $feature_lengths = $helper->execute(-SQL => $union_sql);

  my %feature_lengths;
  foreach (@$feature_lengths) {
    $feature_lengths{$_->[0]}{$_->[1]} = $_->[2];
  }

  return \%feature_lengths;
}

sub feature_lengths_dnadb {
  my ($self, $helper) = @_;
  # The coord_system table is typically not populated in variation dbs,
  # and the coord_system_id column in the seq_region table is set to zero.
  # So get a seq_region_id <=> coord_system_id mapping from the core db.
  # Then, find the longest feature on each seq_region from the variation
  # db, iterate over them and use the mapping to find the longest per
  # coord_system.

  my @tables = $self->feature_tables;

  my $dna_dba = $self->get_dna_dba();

  my $sr_sql = 'SELECT seq_region_id, coord_system_id FROM seq_region';
  my $seq_regions = $dna_dba->dbc->sql_helper->execute_into_hash(-SQL => $sr_sql);

  my %feature_lengths;
  foreach my $table (sort @tables) {
    my $sql = qq/
      SELECT
        seq_region_id, 
        MAX(CAST(seq_region_end AS SIGNED) - CAST(seq_region_start AS SIGNED)) + 1 AS max_length
      FROM
        $table
      GROUP BY seq_region_id
    /;
    my $max_lengths = $helper->execute_into_hash(-SQL => $sql);
    foreach my $sr_id (keys %$max_lengths) {
      my $cs_id = $$seq_regions{$sr_id};
      $feature_lengths{$table}{$cs_id} = 0 unless exists $feature_lengths{$table}{$cs_id};
      if ($$max_lengths{$sr_id} > $feature_lengths{$table}{$cs_id}) {
        $feature_lengths{$table}{$cs_id} = $$max_lengths{$sr_id};
      }
    }
  }

  return \%feature_lengths;
}

sub feature_tables {
  my ($self) = @_;

  my @tables;
  if ($self->dba->group eq 'funcgen') {
    @tables = qw/
      external_feature
      mirna_target_feature
      motif_feature
      peak
      probe_feature
      regulatory_feature
    /;
  } elsif ($self->dba->group eq 'variation') {
    @tables = qw/
      compressed_genotype_region
      phenotype_feature
      read_coverage
      structural_variation_feature
      variation_feature
    /;
  } else {
    @tables = qw/
      assembly_exception
      density_feature
      ditag_feature
      dna_align_feature
      exon
      gene
      karyotype
      marker_feature
      misc_feature
      prediction_exon
      prediction_transcript
      protein_align_feature
      repeat_feature
      simple_feature
      transcript
    /;
  }
  return @tables;
}

1;
