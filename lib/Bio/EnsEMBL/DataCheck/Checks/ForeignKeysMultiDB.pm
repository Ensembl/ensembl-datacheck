=head1 LICENSE

Copyright [2018] EMBL-European Bioinformatics Institute

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
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ForeignKeysMultiDB',
  DESCRIPTION => 'Check for broken foreign key relationships between tables from multiple databases',
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
  # Core <-> Variation database relationships. We assume that the dbs are
  # on the same server; not ideal, but should be good enough in practice.

  my $dna_dba = $self->get_dna_dba();
  my $core_db = $dna_dba->dbc->dbname();

  fk($self->dba, 'transcript_variation', 'feature_stable_id', "$core_db.transcript", 'stable_id');

  fk($self->dba, 'variation_feature',            'seq_region_id', "$core_db.seq_region");
  fk($self->dba, 'structural_variation_feature', 'seq_region_id', "$core_db.seq_region");

  denormalized($self->dba, 'seq_region', 'seq_region_id', 'name', "$core_db.seq_region");
}

sub variation_funcgen_fk {
  my ($self) = @_;
  # Funcgen <-> Variation database relationships. We assume that the dbs are
  # on the same server; not ideal, but should be good enough in practice.

  SKIP: {
    my $funcgen_dba = $self->get_dba(undef, 'funcgen');

    my $sql = q/
      SELECT COUNT(name) FROM regulatory_build 
      WHERE is_current=1
    /;

    skip 'The database has no regulatory build', 1 unless sql_count($funcgen_dba, $sql);

    my $funcgen_db = $funcgen_dba->dbc->dbname();

    fk($self->dba, 'motif_feature_variation', 'feature_stable_id', "$funcgen_db.motif_feature", 'stable_id');
    fk($self->dba, 'regulatory_feature_variation', 'feature_stable_id', "$funcgen_db.regulatory_feature", 'stable_id');
  }
}

sub funcgen_core_fk {
  my ($self) = @_;
  # Core <-> Funcgen database relationships. We assume that the dbs are
  # on the same server; not ideal, but should be good enough in practice.

  my $dna_dba = $self->get_dna_dba();
  my $core_db = $dna_dba->dbc->dbname();

  fk($self->dba, 'probe_feature_transcript', 'stable_id', "$core_db.transcript");
  fk($self->dba, 'probe_set_transcript',     'stable_id', "$core_db.transcript");
  fk($self->dba, 'probe_transcript',         'stable_id', "$core_db.transcript");

  fk($self->dba, 'external_feature',     'seq_region_id', "$core_db.seq_region");
  fk($self->dba, 'mirna_target_feature', 'seq_region_id', "$core_db.seq_region");
  fk($self->dba, 'motif_feature',        'seq_region_id', "$core_db.seq_region");
  fk($self->dba, 'peak',                 'seq_region_id', "$core_db.seq_region");
  fk($self->dba, 'probe_feature',        'seq_region_id', "$core_db.seq_region");
  fk($self->dba, 'regulatory_feature',   'seq_region_id', "$core_db.seq_region");
}

1;
