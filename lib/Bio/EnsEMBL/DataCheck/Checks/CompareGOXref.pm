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

package Bio::EnsEMBL::DataCheck::Checks::CompareGOXref;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareGOXref',
  DESCRIPTION    => 'Compare GO xref counts between two databases, categorised by source',
  GROUPS         => ['compare_core', 'xref'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core']
};

sub tests {
  my ($self) = @_;

  SKIP: {
    my $old_dba = $self->get_old_dba();

    skip 'No old version of database', 1 unless defined $old_dba;

    $self->go_xref_counts($old_dba);
  }
}

sub go_xref_counts {
  my ($self, $old_dba) = @_;

  my $minimum_count = 500;

  my $desc = "Consistent GO xref counts between ".
             $self->dba->dbc->dbname.
             ' (species_id '.$self->dba->species_id.') and '.
             $old_dba->dbc->dbname.
             ' (species_id '.$old_dba->species_id.')';
  my $sql  = qq/
    SELECT edb2.db_name, COUNT(*) FROM
      external_db edb1 INNER JOIN
      xref x1 ON edb1.external_db_id = x1.external_db_id INNER JOIN
      object_xref ox ON x1.xref_id = ox.xref_id INNER JOIN
      ontology_xref ontx ON ox.object_xref_id = ontx.object_xref_id INNER JOIN
      xref x2 ON ontx.source_xref_id = x2.xref_id INNER JOIN
      external_db edb2 ON x2.external_db_id = edb2.external_db_id INNER JOIN
      transcript t ON ox.ensembl_id = t.transcript_id INNER JOIN 
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE
      edb1.db_name = 'GO' AND
      ox.ensembl_object_type = 'Transcript' AND
      cs.species_id = %d
    GROUP BY edb2.db_name
    HAVING COUNT(*) > $minimum_count
  /;
  my $sql1 = sprintf($sql, $self->dba->species_id);
  my $sql2 = sprintf($sql, $old_dba->species_id);
  row_subtotals($self->dba, $old_dba, $sql1, $sql2, 0.70, $desc);
}

1;
