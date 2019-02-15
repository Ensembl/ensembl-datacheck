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

package Bio::EnsEMBL::DataCheck::Checks::CompareBiotypeGroup;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareBiotypeGroup',
  DESCRIPTION    => 'Compare gene counts between two databases, categorised by biotype',
  GROUPS         => ['compare_core'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['biotype', 'coord_system', 'gene', 'seq_region'],
};

sub tests {
  my ($self) = @_;

  SKIP: {
    my $old_dba = $self->get_old_dba();

    skip 'No old version of database', 1 unless defined $old_dba;

    my $desc = 'Consistent gene counts between '.
               $self->dba->dbc->dbname.' and '.$old_dba->dbc->dbname;
    my $sql  = q/
      SELECT biotype_group, COUNT(*) FROM
        biotype INNER JOIN
        gene ON biotype.name = gene.biotype INNER JOIN
        seq_region USING (seq_region_id) INNER JOIN
        coord_system USING (coord_system_id)
      WHERE species_id = %d
      GROUP BY biotype_group
    /;
    my $sql1 = sprintf($sql, $self->dba->species_id);
    my $sql2 = sprintf($sql, $old_dba->species_id);
    row_subtotals($self->dba, $old_dba, $sql1, $sql2, 0.75, $desc);
  }
}

1;
