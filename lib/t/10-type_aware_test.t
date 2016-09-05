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
use Bio::EnsEMBL::DataTest::BaseTest;
use Test::More;
use Data::Dumper;
use Bio::EnsEMBL::DataTest::Utils::TestUtils qw/run_test/;
use Bio::EnsEMBL::Test::MultiTestDB;

BEGIN {
	use_ok( 'Bio::EnsEMBL::DataTest::TypeAwareTest' );
}

diag("Loading test databases");

my $homo = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $core_dba = $homo->get_DBAdaptor('core');
my $variation_dba = $homo->get_DBAdaptor('variation');

diag("Instantiating and executing a TypeAwareTest on a human core");

my $test = Bio::EnsEMBL::DataTest::TypeAwareTest->new(
  name => "mytest",
  db_types => ['core'],
  test => sub {
    ok( 1 == 1, "OK?" );
  } );
  
ok($test,"Simple test OK");

my $res = $test->run($core_dba);
ok($res,"Test output OK");
diag(Dumper($res));
is($res->{pass}, 1, 'Passed');
is(scalar(@{$res->{details}}), 1, '1 detail');
is($res->{details}->[0]->{ok}, 1, 'Detail 1 OK');

my $res2 = $test->run($variation_dba);
ok($res2,"Test output OK");
diag(Dumper($res2));
is(ref($res2), 'HASH', "Is a hashref");

diag("Instantiating and executing a TypeAwareTest on a human variation to make sure it skips");

is($res2->{skipped}, 1, 'Skipped');
is($res2->{reason}, "Test will not work with a variation database", 'Reason for skipping');

done_testing;
