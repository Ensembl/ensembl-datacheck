package Bio::EnsEMBL::DataTest::TableAwareTest;
use Moose;
use Carp;
use Data::Dumper;
use Bio::EnsEMBL::DataTest::Utils::DBUtils qw/table_dates/;

extends 'Bio::EnsEMBL::DataTest::TypeAwareTest';

has 'tables' => ( is => 'ro', isa => 'ArrayRef[Str]' );

override 'will_test' => sub {

  my ( $self, $dba, $table_info ) = @_;

  my $result = super();

  if ( $result->{run} != 1 ) {
    return $result;
  }
  return $self->check_tables( $dba, $table_info );
};

sub check_tables {
  my ( $self, $dba, $table_info ) = @_;
  if ( !defined $table_info ) {
    return { run => 1, reason => "No table info supplied" };
  }
  my $tgt_info = table_dates( $dba->dbc(), $dba->dbc()->dbname() );
  # check each specified table
  for my $table  (@{$self->tables()} ) {
    if ( !defined $tgt_info->{$table} ||
         !defined $table_info->{$table} ||
         $table_info->{$table} ne $tgt_info->{$table} )
    {
      return { run => 1, reason => "Table $table has changed" };
    }
  }
  # no change
  return {
    run    => 0,
    reason => "Table(s) " .
      join( ',', @{$self->{tables}} ) . " have not changed"
  };
}

1;
