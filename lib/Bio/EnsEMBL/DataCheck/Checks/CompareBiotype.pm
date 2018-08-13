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

package Bio::EnsEMBL::DataCheck::Checks::CompareBiotype;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'CompareBiotype',
  DESCRIPTION => 'Check for more than 25% difference between the number of genes '.
                 'in two databases, broken down by biotype.',
  DB_TYPES    => ['core'],
  TABLES      => ['gene'],
  GROUPS      => ['handover'],
};

sub tests {
  my ($self) = @_;

  SKIP: {
    my $old_dba = $self->get_old_dba();

    skip 'No old version of database', 1 unless defined $old_dba;

    diag('Comparing '.$self->dba->dbc->dbname.' and '.$old_dba->dbc->dbname);
    diag('Species '.$self->species.', '.$self->dba->species);
    my $desc = 'Consistent gene counts';
    my $sql  = q/
      SELECT biotype, COUNT(*) FROM
        gene INNER JOIN
        seq_region USING (seq_region_id) INNER JOIN
        coord_system USING (coord_system_id)
      WHERE species_id = %d
      GROUP BY biotype
    /;
    my $sql1 = sprintf($sql, $self->dba->species_id);
    my $sql2 = sprintf($sql, $old_dba->species_id);
    diag($sql1);
    diag($sql2);
    row_subtotals($self->dba, $old_dba, $sql1, $sql2, 0.75, $desc);
  }
}

1;
