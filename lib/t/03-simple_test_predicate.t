#!/usr/bin/env perl
use warnings;
use strict;
use Bio::EnsEMBL::DataTest::BaseTest;
use Test::More;
use Data::Dumper;
use Bio::EnsEMBL::DataTest::Utils::TestUtils qw/run_test/;

BEGIN {
	use_ok( 'Bio::EnsEMBL::DataTest::BaseTest' );
}


my $test = Bio::EnsEMBL::DataTest::BaseTest->new(
  name => "mytest",
  test_predicate => sub {
    return {run=>0, reason=>"Don't want to"}
  },
  test => sub {
    ok( 1 == 1, "OK?" );
  } );
  
ok($test,"Simple test OK");

my $will_test = $test->will_test();
ok($will_test, "will test ran");
is($will_test->{run}, 0, "Will not run test");
my $res = run_test(sub {
  $test->run();
});
ok($res,"Test output OK");
diag(Dumper($res));
is(ref($res), 'HASH', "Is a hashref");

is($res->{skipped}, 1, 'Skipped');
is($res->{reason}, "Don't want to", 'Reason for skipping');

done_testing;
