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

package Bio::EnsEMBL::DataCheck::Checks::MetaKeyLevel;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MetaKeyLevel',
  DESCRIPTION => 'Meta keys are correctly assigned at species or database level',
  GROUPS      => ['core', 'corelike', 'funcgen', 'meta', 'variation'],
  DB_TYPES    => ['cdna', 'core', 'funcgen', 'otherfeatures', 'rnaseq', 'variation'],
  TABLES      => ['meta'],
  PER_DB      => 1,
};

sub tests {
  my ($self) = @_;

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
}

1;
