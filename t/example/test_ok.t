use warnings;
use strict;

use Bio::EnsEMBL::DataTest::BaseTest;
use Test::More;

Bio::EnsEMBL::DataTest::BaseTest->new(
    name => "test_ok",
    test => sub {
        ok(1==1,"OK?");
    }
    );
