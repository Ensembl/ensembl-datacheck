=head1 LICENSE

Copyright [2018-2023] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::MLSSTagMaxAlign;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Utils qw/ hash_diff /;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MLSSTagMaxAlign',
  DESCRIPTION => 'Max align tags have correct values',
  GROUPS      => ['compara', 'compara_genome_alignments'],
  DB_TYPES    => ['compara'],
  TABLES      => ['method_link', 'method_link_species_set', 'method_link_species_set_tag']
};

sub tests {
  my ($self) = @_;

  my $desc = "MLSS tags have correct max_align values";
  my $max_align_values = $self->max_align_values();
  my $dnafrag_calcs    = $self->dnafrag_calcs();

  is_deeply($max_align_values, $dnafrag_calcs, $desc) ||
    diag explain hash_diff($max_align_values, $dnafrag_calcs, 'tag values', 'dnafrags');
}

sub max_align_values {
  my ($self) = @_;

  my $helper = $self->dba->dbc->sql_helper;

  my $sql = qq/
    SELECT
      method_link_species_set_id,
      value
    FROM
      method_link_species_set_tag
    WHERE
      tag = "max_align"
  /;
  my $max_align_values = $helper->execute_into_hash(-SQL => $sql);

  return $max_align_values;
}

sub dnafrag_calcs {
  my ($self) = @_;

  my $helper = $self->dba->dbc->sql_helper;

  my $sql = qq/
    SELECT
      method_link_species_set_id,
      MAX(dnafrag_end - dnafrag_start) + 2 AS max_align
    FROM
      constrained_element
    GROUP BY method_link_species_set_id
    UNION
    SELECT
      method_link_species_set_id,
      MAX(dnafrag_end - dnafrag_start) + 2 AS max_align
    FROM
      genomic_align
    GROUP BY method_link_species_set_id
  /;
  my $dnafrag_calcs = $helper->execute_into_hash(-SQL => $sql);

  return $dnafrag_calcs;
}

1;
