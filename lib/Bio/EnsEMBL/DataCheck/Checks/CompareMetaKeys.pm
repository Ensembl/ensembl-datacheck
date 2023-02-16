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

package Bio::EnsEMBL::DataCheck::Checks::CompareMetaKeys;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Utils qw/hash_diff/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'CompareMetaKeys',
  DESCRIPTION => 'Ensure that appropriate meta_keys are updated when the assembly or geneset changes',
  GROUPS      => ['assembly', 'core', 'geneset', 'meta'],
  DB_TYPES    => ['core'],
  TABLES      => ['assembly', 'attrib_type', 'biotype', 'coord_system', 'exon', 'exon_transcript', 'gene', 'meta', 'seq_region', 'seq_region_attrib', 'transcript', 'translation']
};

sub tests {
  my ($self) = @_;

  SKIP: {
    my $old_dba = $self->get_old_dba();

    skip 'No old version of database', 1 unless defined $old_dba;

    my $compare_dbs = $self->dba->dbc->dbname.' and '.$old_dba->dbc->dbname;

    # If the meta_key has changed, we don't need to do anything; if
    # it hasn't, only then need to try to detect any changes.

    my $mca = $self->dba->get_adaptor('MetaContainer');
    my $old_mca = $old_dba->get_adaptor('MetaContainer');

    my $assembly = $mca->single_value_by_key('assembly.default');
    my $old_assembly = $old_mca->single_value_by_key('assembly.default');

    if ($assembly eq $old_assembly) {
      $self->assembly_changes($old_dba, $compare_dbs);
    } else {
      my $desc = "Meta key 'assembly.default' is different between $compare_dbs";
      isnt($assembly, $old_assembly, $desc);
    }

    # genebuild.last_geneset_update is optional, but is how vertebrates
    # typically track geneset changes. If that doesn't exist, fall back
    # to genebuild.start_date, which is how EG tend to track changes,
    # and is mandatory. We deliberately do not use genebuild.version,
    # because that is an external name for the geneset. If we fix a
    # bug in a gene, we still want to register that as a geneset change,
    # for detection in subsequent processing - but this would not lead
    # to a change in the genebuild.version, only in last_geneset_update
    # and/or start_date.
    my $geneset_meta_key = 'genebuild.last_geneset_update';
    my $geneset = $mca->single_value_by_key($geneset_meta_key);
    my $old_geneset = $old_mca->single_value_by_key($geneset_meta_key);

    if (
      !defined($geneset) ||
      !defined($old_geneset) ||
      $geneset eq $old_geneset
      )
    {
      $geneset_meta_key = 'genebuild.start_date';
      $geneset = $mca->single_value_by_key($geneset_meta_key);
      $old_geneset = $old_mca->single_value_by_key($geneset_meta_key);
    }

    if ($geneset eq $old_geneset) {
      $self->geneset_changes($old_dba, $compare_dbs);
    } else {
      my $desc = "Meta key '$geneset_meta_key' is different between $compare_dbs";
      isnt($geneset, $old_geneset, $desc);
    }

    $old_dba->dbc->disconnect_if_idle();
  }
}

sub assembly_changes {
  my ($self, $old_dba, $compare_dbs) = @_;

  # Do a quick overview as the first test, to find obvious problems;
  # this is redundant with the second test, but in the case of
  # failures, having both is useful for diagnostics.
  my $desc_1 = "Assembly coord_system counts are the same between $compare_dbs";
  my $summary = $self->assembly_summary($self->dba);
  my $summary_old = $self->assembly_summary($old_dba);
  my $pass = is_deeply($summary, $summary_old, $desc_1) ||
    diag explain hash_diff($summary, $summary_old, 'current db', 'old db');

  # We could do an MD5 sum on the DNA sequence, but that's
  # probably overkill - it's time-consuming, and not likely to detect
  # anything that a test of the lengths would not also detect.
  # Detailed diagnostics are typically not useful in the case of
  # failure - there will tend to be a huge number of differences
  # reported, and having just a single example is good enough to
  # understand the problem.
  my $desc_2 = "Sequence names, lengths, and levels are the same between $compare_dbs";
  my $details = $self->assembly_details($self->dba);
  my $details_old = $self->assembly_details($old_dba);
  is_deeply($details, $details_old, $desc_2);
}

sub geneset_changes {
  my ($self, $old_dba, $compare_dbs) = @_;

  # Do a quick overview as the first test, to find obvious problems;
  # this is redundant with the second test, but in the case of
  # failures, having both is useful for diagnostics.
  my $desc_1 = "Gene counts are the same between $compare_dbs";
  my $summary = $self->geneset_summary($self->dba);
  my $summary_old = $self->geneset_summary($old_dba);
  my $pass = is_deeply($summary, $summary_old, $desc_1) ||
    diag explain hash_diff($summary, $summary_old, 'current db', 'old db');

  # Detailed diagnostics are typically not useful in the case of
  # failure - there will tend to be a huge number of differences
  # reported, and having just a single example is good enough to
  # understand the problem.
  my $desc_2 = "Gene IDs, positions, and biotype groups are the same between $compare_dbs";
  my $details = $self->geneset_details($self->dba);
  my $details_old = $self->geneset_details($old_dba);
  is_deeply($details, $details_old, $desc_2);
}

sub assembly_summary {
  my ($self, $dba) = @_;
  my $helper = $dba->dbc->sql_helper;
  my $species_id = $dba->species_id;

  my $sql = qq/
    SELECT cs.name, COUNT(sr.seq_region_id) FROM
      coord_system cs INNER JOIN
      seq_region sr USING (coord_system_id)
    WHERE
      cs.attrib REGEXP 'default_version' AND
      cs.name <> 'lrg' AND
      sr.name NOT LIKE 'LRG_%' AND
      cs.species_id = ?
    GROUP BY cs.name
  /;

  my $assembly_summary =
    $helper->execute_into_hash(
      -SQL      => $sql,
      -PARAMS   => [$species_id]
    );

  return $assembly_summary;
}

sub assembly_details {
  my ($self, $dba) = @_;
  my $helper = $dba->dbc->sql_helper;
  my $species_id = $dba->species_id;
  
  my $mapper = sub {
    my ($row, $value) = @_;
    my %row = (
      attrib      => $$row[1],
      length      => $$row[2],
      is_toplevel => $$row[3],
    );
    return \%row;
  };

  my $sql = qq/
    SELECT
      CONCAT(cs.name, '-', sr.name) AS compound_seq_region_name,
      cs.attrib,
      sr.length,
      IF(at.code IS NULL, 0, 1) AS is_toplevel
    FROM
      coord_system cs INNER JOIN
      seq_region sr USING (coord_system_id) LEFT OUTER JOIN
      (
        SELECT seq_region_id, code FROM
          seq_region_attrib INNER JOIN
          attrib_type USING (attrib_type_id)
        WHERE
          code = 'toplevel'
      ) at ON sr.seq_region_id = at.seq_region_id
    WHERE
      cs.attrib REGEXP 'default_version' AND
      cs.name <> 'lrg' AND
      sr.name NOT LIKE 'LRG_%' AND
      cs.species_id = ?
  /;

  my $assembly_details =
    $helper->execute_into_hash(
      -SQL      => $sql,
      -PARAMS   => [$species_id],
      -CALLBACK => $mapper
    );

  return $assembly_details;
}

sub geneset_summary {
  my ($self, $dba) = @_;
  my $helper = $dba->dbc->sql_helper;
  my $species_id = $dba->species_id;

  my $sql = qq/
    SELECT g.biotype, COUNT(g.gene_id) FROM
      gene g INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      cs.name <> 'lrg' AND
      cs.species_id = ?
    GROUP BY g.biotype
  /;

  my $geneset_summary =
    $helper->execute_into_hash(
      -SQL      => $sql,
      -PARAMS   => [$species_id]
    );

  return $geneset_summary;
}

sub geneset_details {
  my ($self, $dba) = @_;
  my $helper = $dba->dbc->sql_helper;
  my $species_id = $dba->species_id;
  
  my $mapper = sub {
    my ($row, $value) = @_;
    my %row = (
      compound_seq_region_name => $$row[1],
      biotype_group            => $$row[2],
      gene_position            => $$row[3],
      transcript_stable_id     => $$row[4],
      transcript_position      => $$row[5],
      translation_stable_id    => $$row[6],
      translation_position     => $$row[7],
      exon_stable_id           => $$row[8],
      exon_position            => $$row[9]
    );
    return \%row;
  };

  my $sql = qq/
    SELECT
      g.stable_id AS gene_stable_id,
      CONCAT(cs.name, '-', sr.name) AS compound_seq_region_name,
      b.biotype_group,
      CONCAT_WS(':', g.seq_region_start, g.seq_region_end, g.seq_region_strand) AS gene_position,
      t.stable_id AS transcript_stable_id,
      CONCAT_WS(':', t.seq_region_start, t.seq_region_end, t.seq_region_strand) AS transcript_position,
      IFNULL(p.stable_id, 'NA') AS translation_stable_id,
      CONCAT_WS(':', IFNULL(p.seq_start, 'NA'), IFNULL(p.seq_end, 'NA')) AS translation_position,
      e.stable_id AS exon_stable_id,
      CONCAT_WS(':', e.seq_region_start, e.seq_region_end, e.seq_region_strand) AS exon_position
    FROM
      gene g INNER JOIN
      biotype b ON g.biotype = b.name INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id) INNER JOIN
      transcript t USING (gene_id) INNER JOIN
      exon_transcript et USING (transcript_id) INNER JOIN
      exon e USING (exon_id) LEFT OUTER JOIN
      translation p USING (transcript_id)
    WHERE
      cs.name <> 'lrg' AND
      cs.species_id = ?
    ORDER BY
      gene_stable_id, 
      transcript_stable_id, 
      translation_stable_id, 
      exon_stable_id
  /;

  my $geneset_details =
    $helper->execute_into_hash(
      -SQL      => $sql,
      -PARAMS   => [$species_id],
      -CALLBACK => $mapper
    );

  return $geneset_details;
}

1;
