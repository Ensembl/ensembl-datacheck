#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use Data::Dumper;
use Bio::EnsEMBL::DataTest::Utils::TestUtils qw/run_test/;
use Bio::EnsEMBL::DataTest::Utils::DBUtils qw/table_dates/;
use Bio::EnsEMBL::Test::MultiTestDB;

BEGIN {
  use_ok('Bio::EnsEMBL::DataTest::TableAwareTest');
}

my $homo     = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $core_dba = $homo->get_DBAdaptor('core');

my $info = table_dates( $core_dba->dbc() );

my $test = Bio::EnsEMBL::DataTest::TableAwareTest->new(
  name     => "mytest",
  db_types => ['core'],
  tables   => ['gene'],
  test     => sub {
    ok( 1 == 1, "OK?" );
  } );

ok( $test, "Simple test OK" );
{
  my $res = run_test(
    sub {
      $test->run( $core_dba, $info );
    } );
  ok( $res, "Test output OK" );
  diag( Dumper($res) );
  is( ref($res), 'HASH', "Is a hashref" );
  is( $res->{skipped}, 1, 'Skipped' );
  is( $res->{reason}, "Table(s) gene have not changed", 'Reason for skipping' );
}

{
  # tweak transcript
  $info->{transcript} = "Now!";
  my $res = run_test(
    sub {
      $test->run( $core_dba, $info );
    } );
  ok( $res, "Test output OK" );
  diag( Dumper($res) );
  is( ref($res), 'HASH', "Is a hashref" );
  is( $res->{skipped}, 1, 'Skipped' );
  is( $res->{reason}, "Table(s) gene have not changed", 'Reason for skipping' );
}

{
  # tweak gene
  $info->{gene} = "New!";
  my $res = run_test(
    sub {
      $test->run( $core_dba, $info );
    } );
  ok( $res, "Test output OK" );
  diag( Dumper($res) );
  is( ref($res),                      'HASH', "Is a hashref" );
  is( $res->{skipped},                0,      'Skipped' );
  is( $res->{pass},                   1,      'Passed' );
  is( scalar( @{ $res->{details} } ), 1,      '1 detail' );
  is( $res->{details}->[0]->{ok},     1,      'Detail 1 OK' );
}

done_testing;
