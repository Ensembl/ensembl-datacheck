=head1 LICENSE

Copyright [2018-2021] EMBL-European Bioinformatics Institute

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
  DESCRIPTION => 'Assembly data and meta keys are consistent',
  GROUPS      => ['assembly', 'core', 'brc4_core', 'meta'],
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
      MD5(cs.version) <> MD5(m.meta_value) AND
      m.species_id = $species_id AND
      cs.species_id = $species_id
    GROUP BY
      cs.name, cs.version
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);

  SKIP: {
    my $sql_assembly_count = qq/
      SELECT COUNT(*) FROM
        assembly a INNER JOIN
        seq_region sr ON a.asm_seq_region_id = sr.seq_region_id INNER JOIN
        coord_system cs ON sr.coord_system_id = cs.coord_system_id
      WHERE
        cs.attrib RLIKE 'default_version' AND
        cs.species_id = $species_id
    /;
    my $assembly_count = sql_count($self->dba, $sql_assembly_count);

    skip 'No assemblies defined', 1 unless $assembly_count;

    $self->mapping_test('assembly');
  }

  SKIP: {
    my $sql_old_assembly_count = qq/
      SELECT COUNT(*) FROM coord_system cs
      WHERE
        (cs.attrib IS NULL OR
         cs.attrib NOT RLIKE 'default_version') AND
        cs.species_id = $species_id
    /;
    my $old_assembly_count = sql_count($self->dba, $sql_old_assembly_count);

    skip 'No old assemblies to map', 1 unless $old_assembly_count;

    $self->mapping_test('liftover');
  }
}

sub mapping_test {
  my ($self, $mapping_type) = @_;

  my $species_id = $self->dba->species_id;
  my $mapping_type_name = ucfirst($mapping_type);

  my $mca = $self->dba->get_adaptor("MetaContainer");
  my $mappings = $mca->list_value_by_key("$mapping_type.mapping");

  my $desc_1 = "$mapping_type_name mapping(s) exists";
  ok(scalar(@$mappings), $desc_1);

  my $desc_2 = "$mapping_type_name mapping has correct format";
  my $desc_3 = "$mapping_type_name mapping has valid coordinate system";

  my $assembly_pattern = qr/([^:]+)(:(.+))?/;
  my $csa = $self->dba->get_adaptor("CoordSystem");

  foreach my $mapping (@$mappings) {
    foreach my $map_element (split(/[|#]/, $mapping)) {
      my ($name, undef, $version) = $map_element =~ $assembly_pattern;
      my $cs = $csa->fetch_by_name($name, $version);

      like($map_element, $assembly_pattern, "$desc_2 ('$map_element' part of '$mapping')");

      ok(defined $cs, "$desc_3 ($name)");
    }
  }

  my $desc_4 = "$mapping_type_name mapping has corresponding meta key";
  
  my $condition = '';
  if ($mapping_type eq 'assembly') {
    $condition .=
      '('.
        '(cs1.version = cs2.version) OR '.
        '(cs1.version IS NULL) OR '.
        '(cs2.version IS NULL)'.
      ') AND';
    $condition .=
      '('.
        '(cs1.attrib rlike "default_version" OR cs2.attrib rlike "default_version") OR '.
        '(cs1.attrib IS NULL AND cs2.attrib IS NULL)'.
      ') AND';
  } elsif ($mapping_type eq 'liftover') {
    $condition .= 'cs1.version <> cs2.version AND';
    $condition .=
      '('.
        '(cs1.attrib IS NULL AND cs2.attrib = "default_version") OR '.
        '(cs1.attrib = "default_version" AND cs2.attrib IS NULL) OR '.
        '(cs1.attrib IS NULL AND cs2.attrib IS NULL)'.
      ') AND';
  }

  my $sql_implicit_mappings = qq/
    SELECT
      cs1.name, cs1.version, cs2.name, cs2.version
    FROM
      coord_system cs1 INNER JOIN
      seq_region sr1 ON cs1.coord_system_id = sr1.coord_system_id INNER JOIN
      assembly a ON sr1.seq_region_id = a.asm_seq_region_id INNER JOIN
      seq_region sr2 ON a.cmp_seq_region_id = sr2.seq_region_id INNER JOIN
      coord_system cs2 ON sr2.coord_system_id = cs2.coord_system_id
    WHERE
      cs1.coord_system_id <> cs2.coord_system_id AND
      $condition
      cs1.species_id = $species_id
    GROUP BY
      cs1.name, cs1.version, cs2.name, cs2.version;
  /;
  my $helper = $self->dba->dbc->sql_helper;
  my $implicit_mappings = $helper->execute(-SQL => $sql_implicit_mappings);

  foreach my $implicit (@$implicit_mappings) {
    my ($name1, $version1, $name2, $version2) = @$implicit;
    $name1 .= ":$version1" if defined $version1;
    $name2 .= ":$version2" if defined $version2;

    my $match = 0;
    foreach my $mapping (@$mappings) {
      if ($mapping =~ /$name1[\|#]$name2/) {
        $match = 1;
        last;
      }
    }
    ok($match, "$desc_4 ($name1#$name2)");
  }
}

1;
