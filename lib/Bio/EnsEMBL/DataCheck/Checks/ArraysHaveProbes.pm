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

package Bio::EnsEMBL::DataCheck::Checks::ArraysHaveProbes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ArraysHaveProbes',
  DESCRIPTION => 'All arrays are associated with probes',
  GROUPS      => ['funcgen', 'probe_mapping'],
  DB_TYPES    => ['funcgen'],
  TABLES      => ['array', 'array_chip', 'probe']
};

sub tests {
  my ($self) = @_;

  my $desc = "Arrays have probes";
  my $diag = "Array has no probes";
  my $sql  = qq/
    SELECT DISTINCT array.name FROM
      array INNER JOIN
      array_chip USING (array_id) LEFT OUTER JOIN
      probe USING (array_chip_id)
    WHERE probe.probe_id IS NULL
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;
