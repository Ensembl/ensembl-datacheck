=head1 LICENSE

Copyright [2016] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Bio::EnsEMBL::DataTest::Utils::DBUtils;
use warnings;
use strict;
use Carp;

BEGIN {
  require Exporter;
  our $VERSION = 1.00;
  our @ISA     = qw(Exporter);
  our @EXPORT  = qw(table_dates);
}

sub table_dates {
  my ( $dbc, $dbname ) = @_;
  # TODO assertion?
  my $type = 'Bio::EnsEMBL::DBSQL::DBConnection';
  if( !defined $dbc || !$dbc->isa($type) ) {
      croak "table_dates() requires $type";
  }
  if ( !defined $dbname ) {
    $dbname = $dbc->dbname();
  }
  return
    $dbc->sql_helper()->execute_into_hash(
     -SQL =>
       'select table_name,update_time from information_schema.tables where table_schema=?',
     -PARAMS => [$dbname] );
}

1;
