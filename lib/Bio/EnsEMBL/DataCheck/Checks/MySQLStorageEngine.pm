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

package Bio::EnsEMBL::DataCheck::Checks::MySQLStorageEngine;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MySQLStorageEngine',
  DESCRIPTION => 'Database schema matches expected MySQL storage engine',
  GROUPS      => ['compara', 'core', 'corelike', 'funcgen', 'schema', 'variation'],
  DB_TYPES    => ['cdna', 'compara', 'core', 'funcgen', 'otherfeatures', 'rnaseq', 'variation'],
  PER_DB      => 1,
};

sub tests {
  my ($self) = @_;
  my $database_name = $self->dba->dbc->dbname;
  my $engine = 'MyISAM';
  my $diag = "Non-$engine table";
  my $desc = "All tables are using MySQL $engine storage engine";
  my $sql = qq/ SELECT TABLE_NAME FROM 
                 information_schema.tables WHERE 
                 table_schema = '$database_name' AND
                 engine <> '$engine'
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}
1;

