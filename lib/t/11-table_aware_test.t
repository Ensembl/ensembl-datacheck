#!/usr/bin/env perl
# Copyright [2016] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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

diag("Loading test databases");

my $homo     = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $core_dba = $homo->get_DBAdaptor('core');

my $info = table_dates( $core_dba->dbc() );

diag("Instatiating and executing a TableAwareTest");

my $test = Bio::EnsEMBL::DataTest::TableAwareTest->new(
  name     => "mytest",
  db_types => ['core'],
  tables   => ['gene'],
  test     => sub {
    ok( 1 == 1, "OK?" );
  } );


diag("Checking that test will not run without changes");

{
  # test with no changes
  my $res = 
      $test->run( $core_dba, $info );
  ok( $res, "Test output OK" );
  diag( Dumper($res) );
  is( ref($res), 'HASH', "Is a hashref" );
  is( $res->{skipped}, 1, 'Skipped' );
  is( $res->{reason}, "Table(s) gene have not changed", 'Reason for skipping' );
}

diag("Checking that test will not run after transcript changed");

{
  # tweak transcript
  $info->{transcript} = "Now!";
  my $res = 
      $test->run( $core_dba, $info );
   
  ok( $res, "Test output OK" );
  diag( Dumper($res) );
  is( ref($res), 'HASH', "Is a hashref" );
  is( $res->{skipped}, 1, 'Skipped' );
  is( $res->{reason}, "Table(s) gene have not changed", 'Reason for skipping' );
}

diag("Checking that test will run after gene changed");

{
  # tweak gene
  $info->{gene} = "New!";
  my $res = 
      $test->run( $core_dba, $info );
  ok( $res, "Test output OK" );
  diag( Dumper($res) );
  is( ref($res),                      'HASH', "Is a hashref" );
  is( $res->{skipped},                0,      'Skipped' );
  is( $res->{pass},                   1,      'Passed' );
  is( scalar( @{ $res->{details} } ), 1,      '1 detail' );
  is( $res->{details}->[0]->{ok},     1,      'Detail 1 OK' );
}


done_testing;
