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

package Bio::EnsEMBL::DataCheck::Checks::FeaturePosition;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'FeaturePosition',
  DESCRIPTION => 'Feature co-ordinates are within the bounds of their seq_region',
  GROUPS      => ['funcgen', 'ersa'],
  DB_TYPES    => ['funcgen'],
  TABLES      => ['external_feature', 'mirna_target_feature', 'motif_feature', 'peak', 'regulatory_feature']
};

sub tests {
  my ($self) = @_;

  my $seq_regions = $self->seq_region_lengths();

  foreach my $table (@{$self->tables}) {
    $self->start_bound_check($table);
    $self->end_bound_check($table, $seq_regions);
  }
}

sub seq_region_lengths {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $dna_dba = $self->get_dna_dba();

  my $sql = qq/
    SELECT seq_region_id, length FROM
	  seq_region INNER JOIN
	  seq_region_attrib USING (seq_region_id) INNER JOIN
	  attrib_type USING (attrib_type_id) INNER JOIN
	  coord_system USING (coord_system_id)
    WHERE
      attrib_type.code = "toplevel" AND
      coord_system.species_id = $species_id;
  /;

  my $seq_regions = $dna_dba->dbc->sql_helper->execute_into_hash( -SQL => $sql );

  return $seq_regions;
}

sub start_bound_check {
  my ($self, $table) = @_;

  my $desc = "No ${table}s beyond start of seq_region";

  my $sql;
  if ($table eq "regulatory_feature") {
    $sql = qq/
      SELECT COUNT(*)
      FROM $table
      WHERE seq_region_start - bound_start_length <= 0
    /;
  } else {
    $sql = qq/
      SELECT COUNT(*)
      FROM $table
      WHERE seq_region_start <= 0
    /;
  }

  is_rows_zero($self->dba, $sql, $desc);
}

sub end_bound_check {
  my ($self, $table, $seq_regions) = @_;

  my $desc = "No ${table}s beyond end of seq_region";

  my $sql;
  if ($table eq "regulatory_feature") {
    $sql = qq/
      SELECT
        seq_region_id,
        MAX(seq_region_end + bound_end_length) AS max_length
      FROM $table
      GROUP BY seq_region_id
    /;
  } else {
    $sql = qq/
      SELECT
        seq_region_id,
        MAX(seq_region_end) AS max_length
      FROM $table
      GROUP BY seq_region_id
    /;
  }

  my $max_ends = $self->dba->dbc->sql_helper->execute_into_hash( -SQL => $sql );

  my @out_of_bounds;

  foreach my $sr_id (keys %$max_ends) {
	if (exists $$seq_regions{$sr_id}) {
	  if ($$max_ends{$sr_id} > $$seq_regions{$sr_id}) {
	    push @out_of_bounds, $sr_id;
	  }
	}
  }

  is(scalar(@out_of_bounds), 0, $desc) ||
    diag explain {'seq_region_ids' => \@out_of_bounds};
}

1;
