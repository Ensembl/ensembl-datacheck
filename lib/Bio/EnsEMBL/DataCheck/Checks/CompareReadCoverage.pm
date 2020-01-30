=head1 LICENSE

Copyright [2018-2020] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CompareReadCoverage;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareReadCoverage',
  DESCRIPTION    => 'Compare read coverage by sample between two databases',
  GROUPS         => ['compare_variation'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['variation'],
  TABLES         => ['read_coverage', 'sample']
};

sub tests {
  my ($self) = @_;
  
  SKIP: {
    my $old_dba = $self->get_old_dba();

    skip 'No old version of database', 1 unless defined $old_dba;

    my $desc = "Consistent read coverage by sample between ".
               $self->dba->dbc->dbname.' and '.$old_dba->dbc->dbname;
    my $sql  = q/
      SELECT s.name, COUNT(*) 
      FROM read_coverage rc JOIN sample s 
        ON (s.sample_id = rc.sample_id) 
      GROUP BY s.name
    /;
    row_subtotals($self->dba, $old_dba, $sql, undef, 1.00, $desc);
  }
}

1;
