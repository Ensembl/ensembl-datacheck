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

package Bio::EnsEMBL::DataCheck::Checks::MetaKeyAssembly;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MetaKeyAssembly',
  DESCRIPTION => 'Check for consistency between assembly data and meta keys',
  GROUPS      => ['core_handover'],
  DB_TYPES    => ['core'],
  TABLES      => ['assembly', 'attrib_type', 'coord_system', 'meta', 'seq_region', 'seq_region_attrib']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc_1 = 'Assembly name matches in coord_system and meta tables';
  my $sql_1  = qq/
    SELECT cs.name, cs.version FROM
      meta m,
      coord_system cs INNER JOIN
      seq_region sr USING (coord_system_id) INNER JOIN
      seq_region_attrib sra USING (seq_region_id) INNER JOIN
      attrib_type at USING (attrib_type_id)
    WHERE
      cs.attrib RLIKE 'default_version' AND
      at.code = 'toplevel' AND
      m.meta_key = 'assembly.default' AND
      cs.version <> m.meta_value AND
      m.species_id = $species_id AND
      cs.species_id = $species_id
    GROUP BY
      cs.name, cs.version
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);

  SKIP: {
    my $sql_assembly_count = qq/
      SELECT COUNT(*) FROM coord_system
      WHERE
        attrib RLIKE 'default_version' AND
        species_id = $species_id
    /;
    my $assembly_count = sql_count($self->dba, $sql_assembly_count);

    skip 'No assemblies defined', 1 unless $assembly_count;

    my $desc = 'Assembly mapping(s) exists';
    my $sql  = qq/
      SELECT COUNT(*) FROM meta
      WHERE
        meta_key = 'assembly.mapping' AND
        species_id = $species_id
    /;
    is_rows_nonzero($self->dba, $sql, $desc);
  }

  SKIP: {
    my $mca = $self->dba->get_adaptor("MetaContainer");
    my $accs = $mca->list_value_by_key('assembly.accession');

    skip 'No assembly accession', 1 unless scalar(@$accs);

    my $desc = 'Accession has expected format';
    like($$accs[0], qr/^GCA_[0-9]+\.[0-9]+/, $desc);
  }

  SKIP: {
    my $sql_liftover_count = qq/
      SELECT COUNT(*) FROM coord_system cs
      WHERE
        cs.attrib NOT RLIKE 'default_version' AND
        cs.species_id = $species_id
    /;
    my $liftover_count = sql_count($self->dba, $sql_liftover_count);

    skip 'No liftover mappings defined', 1 unless $liftover_count;

    my $desc = 'Liftover mapping(s) exists';
    my $sql_meta_count = qq/
      SELECT COUNT(*) FROM meta m
      WHERE
        m.meta_key = 'liftover.mapping' AND
        m.species_id = $species_id
    /;
    my $meta_count = sql_count($self->dba, $sql_meta_count);
    is($liftover_count, $meta_count, $desc);
  }
}

1;