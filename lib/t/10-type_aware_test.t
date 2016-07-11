#!/usr/bin/env perl
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

my $homo = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');
my $core_dba = $homo->get_DBAdaptor('core');
my $variation_dba = $homo->get_DBAdaptor('variation');

my $test = Bio::EnsEMBL::DataTest::TypeAwareTest->new(
  name => "mytest",
  db_types => ['core'],
  test => sub {
    ok( 1 == 1, "OK?" );
  } );
  
ok($test,"Simple test OK");

#my $will_test = $test->will_test();
#ok($will_test, "will test ran");
#is($will_test->{run}, 0, "Will not run test");
my $res = run_test(sub {
  $test->run($core_dba);
});
ok($res,"Test output OK");
diag(Dumper($res));
is($res->{pass}, 1, 'Passed');
is(scalar(@{$res->{details}}), 1, '1 detail');
is($res->{details}->[0]->{ok}, 1, 'Detail 1 OK');

my $res2 = run_test(sub {
  $test->run($variation_dba);
});
ok($res2,"Test output OK");
diag(Dumper($res2));
is(ref($res2), 'HASH', "Is a hashref");

is($res2->{skipped}, 1, 'Skipped');
is($res2->{reason}, "Test will not work with a variation database", 'Reason for skipping');

done_testing;
