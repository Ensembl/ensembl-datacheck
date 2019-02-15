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

package Bio::EnsEMBL::DataCheck::Checks::CompareXref;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareXref',
  DESCRIPTION    => 'Compare xref counts between two databases, categorised by external_db',
  GROUPS         => ['compare_core', 'xref'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core']
};

sub tests {
  my ($self) = @_;

  SKIP: {
    my $old_dba = $self->get_old_dba();

    skip 'No old version of database', 1 unless defined $old_dba;

    $self->xref_counts($old_dba, 'gene');
    $self->xref_counts($old_dba, 'transcript');
    $self->xref_counts($old_dba, 'translation');
  }
}

sub xref_counts {
  my ($self, $old_dba, $table) = @_;

  my $table_sql = "$table ON ensembl_id = ${table}_id INNER JOIN ";
  if ($table eq 'translation') {
    $table_sql .= 'transcript USING (transcript_id) INNER JOIN ';
  }
  my $table_obj = ucfirst($table);

  my $minimum_count = 500;

  my $desc = "Consistent $table xref counts between ".
             $self->dba->dbc->dbname.
             ' (species_id '.$self->dba->species_id.') and '.
             $old_dba->dbc->dbname.
             ' (species_id '.$old_dba->species_id.')';
  my $sql  = qq/
    SELECT db_name, COUNT(*) FROM
      external_db INNER JOIN
      xref USING (external_db_id) INNER JOIN
      object_xref USING (xref_id) INNER JOIN
      $table_sql
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id)
    WHERE
      db_name <> 'GO' AND
      info_type <> 'PROJECTION' AND
      ensembl_object_type = '$table_obj' AND
      species_id = %d
    GROUP BY db_name
    HAVING COUNT(*) > $minimum_count
  /;
  my $sql1 = sprintf($sql, $self->dba->species_id);
  my $sql2 = sprintf($sql, $old_dba->species_id);
  row_subtotals($self->dba, $old_dba, $sql1, $sql2, 0.70, $desc);
}

1;
