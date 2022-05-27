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

package Bio::EnsEMBL::DataCheck::Checks::MetaKeyConsistent;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Utils qw/ array_diff hash_diff /;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MetaKeyConsistent',
  DESCRIPTION => 'Assembly and species meta keys are identical between core and core-like databases',
  GROUPS      => ['core_sync', 'corelike', 'meta'],
  DB_TYPES    => ['cdna', 'otherfeatures', 'rnaseq'],
  TABLES      => ['meta'],
  FORCE       => 1
};

sub tests {
  my ($self) = @_;

  my $desc_dna_dba = 'Core database found';
  my $dna_dba = $self->get_dna_dba();
  my $pass = ok(defined $dna_dba, $desc_dna_dba);

  if ($pass) {
    my $identical_corelike = $self->identical_meta_keys($self->dba);
    my $identical_core = $self->identical_meta_keys($dna_dba);

    my $desc_1 = 'Identical assembly.* meta keys in core and core-like databases';
    is_deeply($identical_corelike, $identical_core, $desc_1) ||
      diag explain hash_diff($identical_corelike, $identical_core, 'core-like db', 'core db');

    my $consistent_corelike = $self->consistent_meta_keys($self->dba);
    my $consistent_core = $self->consistent_meta_keys($dna_dba);

    my $desc_2 = 'Consistent species.* meta keys in core and core-like databases';
    is_deeply($consistent_corelike, $consistent_core, $desc_2) ||
      diag explain array_diff($consistent_corelike, $consistent_core, 'core-like db', 'core db');
  }
}

sub identical_meta_keys {
  my ($self, $dba) = @_;

  my $helper = $dba->dbc->sql_helper;

  my $species_id = $dba->species_id;

  my $sql = qq/
    SELECT
      meta_id,
      CONCAT(meta_key, ': ', meta_value) AS meta_key_value_pair
    FROM
      meta
    WHERE
      meta_key RLIKE 'assembly|liftover|lrg' AND
      meta_key NOT LIKE 'assembly.web_accession%' AND
      meta_key NOT LIKE 'assembly.provider%' AND
      species_id = $species_id
  /;
  my $identical_meta_keys = $helper->execute_into_hash(-SQL => $sql);

  return $identical_meta_keys;
}

sub consistent_meta_keys {
  my ($self, $dba) = @_;

  my $helper = $dba->dbc->sql_helper;

  my $species_id = $dba->species_id;

  my $sql = qq/
    SELECT
      CONCAT(meta_key, ':', meta_value) AS meta_key_value_pair
    FROM
      meta
    WHERE
      meta_key LIKE 'species.%' AND
      meta_key <> 'species.biomart_dataset' AND
      species_id = $species_id
    ORDER BY
      meta_key_value_pair
  /;
  my $consistent_meta_keys = $helper->execute_simple(-SQL => $sql);

  return $consistent_meta_keys;
}

1;
