=head1 LICENSE

Copyright [2018-2022] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::ComparePreviousVersionProbes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'ComparePreviousVersionProbes',
  DESCRIPTION    => 'Checks for loss of Probes between database versions',
  GROUPS         => ['probe_mapping'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['funcgen'],
  TABLES         => ['array', 'array_chip', 'probe']
};

sub tests {
  my ($self) = @_;
  SKIP: {
    my $previous_dba = $self->get_old_dba();


    skip 'No previous version of database', 1 unless defined $previous_dba;

    my $desc_decrease = "Checking if number of probes has decreased between ".
                 $self->dba->dbc->dbname.' and '.$previous_dba->dbc->dbname;
    my $desc_increase = "Checking if number of probes has increased between ".
                 $self->dba->dbc->dbname.' and '.$previous_dba->dbc->dbname;
    my $min_proportion = 0.9;

    my $sql = qq/
      select array.name, count(distinct probe_id)
      from array join array_chip using (array_id)
      join probe using (array_chip_id)
      group by array.name order by array.name/;

    row_subtotals($self->dba, $previous_dba, $sql, undef, $min_proportion, $desc_decrease);
    row_subtotals($previous_dba, $self->dba, $sql, undef, $min_proportion, $desc_increase);


  }

}

1;

