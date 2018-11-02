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

package Bio::EnsEMBL::DataCheck::Checks::MetaTable;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MetaTable',
  DESCRIPTION => 'Ensure that meta table has valid meta_keys',
  DB_TYPES    => ['cdna', 'core', 'funcgen', 'otherfeatures', 'rnaseq', 'variation'],
  TABLES      => ['meta'],
  PER_DB      => 1,
};

sub tests {
  my ($self) = @_;

  my $group = $self->dba->group;

  my $sql = qq/
    SELECT meta_key, COUNT(*) FROM meta GROUP BY meta_key
  /;
  my $helper = $self->dba->dbc->sql_helper;
  my %meta_keys = %{ $helper->execute_into_hash(-SQL => $sql) };

  my $prod_sql = qq/
    SELECT name, is_optional
    FROM meta_key
    WHERE FIND_IN_SET('$group', db_type) AND is_current = 1
  /;
  my $prod_helper = $self->get_prod_dba->dbc->sql_helper;
  my %prod_keys   = %{ $prod_helper->execute_into_hash(-SQL => $prod_sql) };

  foreach my $meta_key (keys %meta_keys) {
    my $desc = "Meta key '$meta_key' in production database";
    ok(exists $prod_keys{$meta_key}, $desc);
  }

  foreach my $meta_key (keys %prod_keys) {
    if (!$prod_keys{$meta_key}) {
      my $desc = "Mandatory meta key '$meta_key' exists";
      ok(exists $meta_keys{$meta_key}, $desc);
    }
  }

  my $desc_1 = 'DB-wide meta keys have NULL species_id';
  my $diag_1 = 'Non-NULL species_id';
  my $sql_1  = qq/
    SELECT
      meta_key, species_id FROM meta
    WHERE
      meta_key IN ('patch', 'schema_type', 'schema_version') AND
      species_id IS NOT NULL
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  my $desc_2 = 'Species-related meta keys have non-NULL species_id';
  my $diag_2 = 'NULL species_id';
  my $sql_2  = qq/
    SELECT
      meta_key, species_id FROM meta
    WHERE
      meta_key NOT IN ('patch', 'schema_type', 'schema_version') AND
      species_id IS NULL
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);

  if ($self->dba->group eq 'variation') {
    $self->variation_specific_keys();
  }
}

sub variation_specific_keys {
  my ($self) = @_;

  if ($self->species eq 'homo_sapiens') {
    my $desc_1 = 'Correct default population for human LD';
    my $sql_1  = qq/
      SELECT COUNT(*) FROM
        meta INNER JOIN population ON meta_value = population_id
      WHERE
        meta_key = 'pairwise_ld.default_population'
    /;
    is_rows_nonzero($self->dba, $sql_1, $desc_1);

    my $desc_2 = 'Polyphen version for human';
    my $sql_2  = 'SELECT COUNT(*) FROM meta WHERE meta_key = "polyphen_version"';
    is_rows_nonzero($self->dba, $sql_2, $desc_2);

    my $desc_3 = 'Sift version for human';
    my $sql_3  = 'SELECT COUNT(*) FROM meta WHERE meta_key = "sift_version"';
    is_rows_nonzero($self->dba, $sql_3, $desc_3);

  } elsif ($self->species eq 'canis_familiaris') {
    my $desc = 'Correct default strain for dog';
    my $sql  = qq/
      SELECT COUNT(*) FROM
        meta INNER JOIN sample ON meta_value = name
      WHERE
        meta_key = 'sample.default_strain'
    /;
    is_rows_nonzero($self->dba, $sql, $desc);
  }
}

1;
