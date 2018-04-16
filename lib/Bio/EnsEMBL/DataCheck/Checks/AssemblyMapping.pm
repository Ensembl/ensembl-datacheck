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

package Bio::EnsEMBL::DataCheck::Checks::AssemblyMapping;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use Bio::EnsEMBL::DataCheck::Utils::DBUtils qw/get_species_ids is_rowcount_zero/;

use constant {
  NAME        => 'AssemblyMapping',
  DESCRIPTION => 'Check validity of assembly mappings.',
  GROUPS      => ['assembly', 'handover'],
  DB_TYPES    => ['core'],
  TABLES      => ['meta', 'coord_system'],
};

sub tests {
  my ($self) = @_;
  my $dba = $self->dba;
  my $helper = $dba->dbc->sql_helper;

  my $assembly_pattern = qr/([^:]+)(:(.+))?/;
  my $default_version  = 'NONE';

  my $mappings_sql  = q/
    SELECT meta_value FROM meta
    WHERE meta_key = 'assembly.mapping' AND meta_value IS NOT NULL AND meta_value <> ''
  /;
  my $mappings = $helper->execute_simple(-SQL => $mappings_sql);

  my $coord_systems_sql  = qq/
    SELECT name, IFNULL(version,'$default_version') FROM coord_system
  /;
  my $coord_systems = $helper->execute_into_hash(-SQL => $coord_systems_sql);

  my $desc_1 = 'No null or empty assembly.mapping values';
  my $sql_1  = q/
    SELECT COUNT(*) FROM meta
    WHERE meta_key = 'assembly.mapping' AND (meta_value IS NULL OR meta_value = '')
  /;
  is_rowcount_zero($dba, $sql_1, $desc_1);

  my $desc_2 = 'assembly.mapping element matches expected pattern';
  my $desc_3 = 'assembly.mapping element has valid coordinate system';
  my $desc_4 = 'assembly.mapping element matches coordinate system version';
  foreach my $mapping (@$mappings) {
    foreach my $map_element (split(/[|#]/, $mapping)) {
      my ($name, undef, $version) = $map_element =~ $assembly_pattern;
      $version ||= $default_version;

      like($map_element, $assembly_pattern, $desc_2);
      ok(exists $$coord_systems{$name}, $desc_3);
      if (exists $$coord_systems{$name}) {
        is($$coord_systems{$name}, $version, $desc_4);
      }
    }
  }
}

1;
