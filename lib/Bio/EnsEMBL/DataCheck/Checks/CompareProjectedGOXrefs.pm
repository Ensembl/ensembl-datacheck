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
  GROUPS         => ['compare_core', 'xref'],
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

  my $minimum_count = 1000;
  my $threshold = 0.80;

  my $desc = "Checking GO xref version between ".
             $self->dba->dbc->dbname.
             ' (species_id '.$self->dba->species_id.') and '.
             $old_dba->dbc->dbname.
             ' (species_id '.$old_dba->species_id.')';
  my $sql  = qq/
      SELECT res.species, COUNT(*) FROM 
        (SELECT substring_index(substring_index(info_text,' ',2),' ',-1) as species FROM xref x 
      WHERE 
        dbprimary_acc like 'GO:%' and 
        info_type not in ('UNMAPPED', 'DEPENDENT')) as res
      GROUP BY res.species 
      HAVING COUNT(*) > $minimum_count
  /;
  row_subtotals($self->dba, $old_dba, $sql, undef, $threshold, $desc);
}
1;
