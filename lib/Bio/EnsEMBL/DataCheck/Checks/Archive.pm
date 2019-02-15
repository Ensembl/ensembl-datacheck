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

package Bio::EnsEMBL::DataCheck::Checks::Archive;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'Archive',
  DESCRIPTION => 'Gene archive table is up to date',
  GROUPS      => ['id_mapping'],
  DB_TYPES    => ['core'],
  TABLES      => ['gene_archive', 'stable_id_event'],
  PER_DB      => 1,
};

sub skip_tests {
  my ($self) = @_;

  my $sql = 'SELECT COUNT(*) FROM mapping_session';

  if (! sql_count($self->dba, $sql) ) {
    return (1, 'No stable ID mappings.');
  }
}

sub tests {
  my ($self) = @_;

  $self->changed_in_archive('gene');
  $self->changed_in_archive('transcript');
  $self->changed_in_archive('translation');

  $self->deleted_in_archive('gene');
  $self->deleted_in_archive('transcript');
  $self->deleted_in_archive('translation');
}

sub changed_in_archive {
  my ($self, $type) = @_;

  my $desc = "Changed $type"."s are in archive table";
  my $diag = "$type stable ID has changed, but is not in the gene_archive table";
  my $sql  = qq/
    SELECT CONCAT(old_stable_id, '.', old_version) FROM
      stable_id_event sie LEFT OUTER JOIN
      gene_archive ga ON
        sie.old_stable_id = ga.$type\_stable_id AND
        sie.mapping_session_id = ga.mapping_session_id
    WHERE
      sie.type = '$type' AND
      sie.new_stable_id = sie.old_stable_id AND
      sie.old_version <> sie.new_version AND
      ga.gene_stable_id is NULL
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

sub deleted_in_archive {
  my ($self, $type) = @_;

  my $desc = "Deleted $type"."s are in archive table";
  my $diag = "$type stable ID has been deleted, but is not in the gene_archive table";
  my $sql  = qq/
    SELECT CONCAT(old_stable_id, '.', old_version) FROM
      stable_id_event sie LEFT OUTER JOIN
      gene_archive ga ON
        sie.old_stable_id = ga.$type\_stable_id AND
        sie.mapping_session_id = ga.mapping_session_id
    WHERE
      sie.type = '$type' AND
      sie.new_stable_id IS NULL AND
      ga.gene_stable_id IS NULL
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;
