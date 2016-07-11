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
