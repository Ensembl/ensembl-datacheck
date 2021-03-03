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

package Bio::EnsEMBL::DataCheck::Checks::CompareProjectedGOXrefs;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareProjectedGOXrefs',
  DESCRIPTION    => 'Compare GO xref counts between two databases, categorised by source coming from the info_type',
  GROUPS         => ['compare_core', 'xref', 'xref_go_projection'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['xref']
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
  my $threshold = 0.66;

  my $desc = "Consistent GO xref counts between ".
             $self->dba->dbc->dbname.
             ' (species_id '.$self->dba->species_id.') and '.
             $old_dba->dbc->dbname.
             ' (species_id '.$old_dba->species_id.')';
  my $sql  = qq/
    SELECT proj_source, COUNT(*)
    FROM
      (SELECT
        xref_id,
        substring_index(substring_index(info_text,' ',2),' ',-1) AS proj_source
       FROM xref) x INNER JOIN
      xref USING (xref_id) INNER JOIN
      external_db USING (external_db_id) INNER JOIN
      object_xref USING (xref_id) INNER JOIN
      transcript ON ensembl_id = transcript_id INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id)
    WHERE
      db_name = 'GO' AND
      ensembl_object_type = 'Transcript' AND
      info_type not in ('UNMAPPED', 'DEPENDENT') AND
      species_id = %d
    GROUP BY proj_source
  /;
  my $sql1 = sprintf($sql, $self->dba->species_id);
  my $sql2 = sprintf($sql, $old_dba->species_id);
  row_subtotals($self->dba, $old_dba, $sql1, $sql2, $threshold, $desc, $minimum_count);
}

1;
