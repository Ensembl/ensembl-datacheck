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

package Bio::EnsEMBL::DataCheck::Checks::ComparePreviousVersionSynonyms;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'ComparePreviousVersionSynonyms',
  DESCRIPTION    => 'Compare xref synonyms counts between two databases, categorised by source',
  GROUPS         => ['compare_core', 'xref'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['external_db','external_synonym','xref','object_xref']
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
  my $threshold = 0.78;

  my $desc = "Checking xref synonyms between ".
             $self->dba->dbc->dbname.
             ' (species_id '.$self->dba->species_id.') and '.
             $old_dba->dbc->dbname.
             ' (species_id '.$old_dba->species_id.')';
  my $sql  = qq/
      SELECT e.db_name, COUNT(*) FROM 
        external_db e, 
        external_synonym es, 
        xref x, 
        object_xref ox
      WHERE
        x.xref_id=ox.xref_id AND 
        e.external_db_id=x.external_db_id AND 
        x.xref_id=es.xref_id AND 
        x.info_type <> 'PROJECTION'
      GROUP BY e.db_name 
      HAVING COUNT(*) > $minimum_count
  /;
  row_subtotals($self->dba, $old_dba, $sql, undef, $threshold, $desc);
}
1;