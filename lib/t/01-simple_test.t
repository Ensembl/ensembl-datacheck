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

BEGIN {
	use_ok( 'Bio::EnsEMBL::DataTest::BaseTest' );
}

diag("Instantiating and executing a BaseTest");

my $test = Bio::EnsEMBL::DataTest::BaseTest->new(
  name => "mytest",
  test => sub {
    ok( 1 == 1, "OK?" );
  } );
  
ok($test,"Simple test OK");

my $will_test = $test->will_test();
ok($will_test, "will test ran");
is($will_test->{run}, 1, "Will run test");
my $res = $test->run();
ok($res,"Test output OK");
diag(Dumper($res));
is(ref($res), 'HASH', "Is a hashref");

is($res->{pass}, 1, 'Passed');
is(scalar(@{$res->{details}}), 1, '1 detail');
is($res->{details}->[0]->{ok}, 1, 'Detail 1 OK');

done_testing;
