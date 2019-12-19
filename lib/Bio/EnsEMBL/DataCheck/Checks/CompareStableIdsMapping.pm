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

package Bio::EnsEMBL::DataCheck::Checks::CompareStableIdsMapping;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareStableIdsMapping',
  DESCRIPTION    => 'Stable IDs have been mapped between old and new databases',
  GROUPS         => ['compare_core'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['meta', 'stable_id_event', 'mapping_session', 'gene', 'transcript', 'exon', 'translation'],
};

sub tests {
  my ($self) = @_;

  SKIP: {
    my $old_dba = $self->get_old_dba();

    skip 'No old version of database', 1 unless defined $old_dba;

    my $new_dba = $self->dba;
    my $stable_id_prefix = $new_dba->get_MetaContainerAdaptor->single_value_by_key('species.stable_id_prefix');
    my $old_stable_id_prefix = $old_dba->get_MetaContainerAdaptor->single_value_by_key('species.stable_id_prefix');

    #If the stable ids are different, which should probably not happen we do not check the stable id
    #mapping as it is not needed
    if ($stable_id_prefix ne $old_stable_id_prefix) {
      skip 'Different stable id prefix'.$new_dba->dbc->dbname.' and '.$old_dba->dbc->dbname, 1;
    }

    #If the gene set has changed, we need to make sure that the stable id mapping has been done.
    #If the count for each table is the same as previous release, it is highly unlikely that the
    #gene set has changed
    my $table_num_count = 0;
    my $object_count_sql = 'SELECT COUNT(*) FROM %s';
    my @tables = qw(gene transcript exon translation);
    foreach my $table (@tables) {
      my $old_count = sql_count($old_dba, sprintf($object_count_sql, $table) );
      my $new_count = $new_dba->dbc->sql_helper()->execute_single_result( -SQL => sprintf($object_count_sql, $table) );
      ++$table_num_count if ($old_count == $new_count);
    }
    my $expected_value = 1;
    if ($table_num_count == scalar(@tables)) {
      $expected_value = undef;
    }
    else {
      my $old_session_sql = 'SELECT old_db_name, old_release FROM mapping_session WHERE old_db_name = "'.$old_dba->dbc->dbname.'"';
      is_rows($new_dba, $old_session_sql, 1, 'Checking '.$old_dba->dbc->dbname.' is present in mapping_session as old_db_name');

      my $new_session_sql = 'SELECT new_db_name, new_release FROM mapping_session WHERE new_db_name = "'.$new_dba->dbc->dbname.'"';
      is_rows($new_dba, $new_session_sql, 1, 'Checking '.$new_dba->dbc->dbname.' is present in mapping_session as new_db_name');
    }

    #If the gene set has changed we expect the count to be higher than the previous database, hence minimum value is 1.
    #Otherwise we expect the row count to be equal.
    #In the unlikely event of extending exon and causing a change of version in the gene, transcript or translation, the
    #datacheck will either erroneously fail or succeed.
    my $stable_id_event_sql = 'SELECT old_stable_id, new_stable_id FROM stable_id_event';
    my $stable_id_event_desc = 'Check that the stable_id_event table has as many or more rows than the previous database';
    row_totals($new_dba, $old_dba, $stable_id_event_sql, undef, $expected_value, $stable_id_event_desc);
  }
}

1;
