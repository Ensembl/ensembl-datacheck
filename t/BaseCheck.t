# Copyright [2018] EMBL-European Bioinformatics Institute
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

use strict;
use warnings;

use Bio::EnsEMBL::DataCheck::BaseCheck;

use FindBin;
use Test::More;

use lib "$FindBin::Bin/TestChecks";
use BaseCheck_1;
use BaseCheck_2;
use BaseCheck_3;

# Note that you cannot, by design, create a BaseCheck object; datachecks
# must inherit from it and define mandatory, read-only parameters that
# are specific to that particular datacheck. So there's a limited amount
# of testing that we can do on the base class, the functionality is
# tested on subclasses defined in TestChecks.

my $module = 'Bio::EnsEMBL::DataCheck::BaseCheck';

diag('Fixed attributes');
can_ok($module, qw(name description groups datacheck_type));

diag('Internal attributes');
can_ok($module, qw(_started _finished _passed));

diag('Methods');
can_ok($module, qw(skip_datacheck tests run));

# As well as being a nice way to encapsulate sets of tests, the use of
# subtests here is necessary, because the behaviour we are testing
# involves running tests, and we need to isolate that from the reports
# of this test (i.e. BaseCheck.t).

subtest 'Minimal DataCheck with passing tests', sub {
  my $basecheck = TestChecks::BaseCheck_1->new();
  isa_ok($basecheck, $module);

  like($basecheck->name,           qr/^\w+$/,  'name attribute is a string of word characters');
  like($basecheck->description,    qr/.+/,     'description attribute is a string');
  is_deeply($basecheck->groups,    [],         'groups attribute defaults to empty list');
  is($basecheck->datacheck_type,   'critical', 'datacheck_type attribute defaults to "critical"');
  is($basecheck->_started,         undef,      '_started attribute undefined by default');
  is($basecheck->_finished,        undef,      '_finished attribute undefined by default');
  is($basecheck->_passed,          undef,      '_passed attribute undefined by default');
  is($basecheck->skip_datacheck(), undef,      'skip_datacheck method undefined by default');

  # The tests that are run are Test::More tests. Running them within a test
  # is a bit confusing. To simulate a proper test of the tests, need to reset
  # the Test::More framework.
  Test::More->builder->reset();
  my $output = $basecheck->run;

  my $name = $basecheck->name;
  diag("Test enumeration reset by the datacheck object ($name)");

  like($output, qr/# Subtest\: $name/m, 'tests ran as subtests');
  like($output, qr/^\s+1\.\.2/m,        '2 subtests ran successfully');
  like($output, qr/^\s+ok 1 - $name/m,  'test ran successfully');
  like($output, qr/^\s+1\.\.1/m,        'test ran with a plan');

  like($basecheck->_started,  qr/^\d+$/, '_started attribute has numeric value');
  like($basecheck->_finished, qr/^\d+$/, '_finished attribute has numeric value');
  is($basecheck->_passed,     1,         '_passed attribute is true');
};

subtest 'DataCheck with non-default attributes and failing test', sub {
  my $basecheck = TestChecks::BaseCheck_2->new();
  isa_ok($basecheck, $module);

  like($basecheck->name,           qr/^\w+$/,  'name attribute is a string of word characters');
  like($basecheck->description,    qr/.+/,     'description attribute is a string');
  is(scalar @{$basecheck->groups}, 1,          'groups attribute is a one-element list');
  is($basecheck->datacheck_type,   'advisory', 'datacheck_type attribute set to "advisory"');

  # The tests that are run are Test::More tests. Running them within a test
  # is a bit confusing. To simulate a proper test of the tests, need to reset
  # the Test::More framework.
  Test::More->builder->reset();
  my $output = $basecheck->run;

  my $name = $basecheck->name;
  diag("Test enumeration reset by the datacheck object ($name)");

  like($output, qr/# Subtest\: $name/m,    'tests ran as subtests');
  like($output, qr/^\s+not ok 1/m,         '1 subtest failed');
  like($output, qr/^\s+not ok 1 - $name/m, 'test failed');
  like($output, qr/^\s+1\.\.1/m,           'test ran with a plan');

  like($basecheck->_started,  qr/^\d+$/, '_started attribute has numeric value');
  like($basecheck->_finished, qr/^\d+$/, '_finished attribute has numeric value');
  is($basecheck->_passed,     0,         '_passed attribute is false');
};

subtest 'DataCheck with skipping test', sub {
  my $basecheck = TestChecks::BaseCheck_3->new();
  isa_ok($basecheck, $module);

  # The tests that are run are Test::More tests. Running them within a test
  # is a bit confusing. To simulate a proper test of the tests, need to reset
  # the Test::More framework.
  Test::More->builder->reset();
  my $output = $basecheck->run;

  my $name = $basecheck->name;
  diag("Test enumeration reset by the datacheck object ($name)");

  like($output, qr/# Subtest\: $name/m,   'tests ran as subtests');
  like($output, qr/\s+1\.\.0 # SKIP .+/m, 'All subtests skipped');
  like($output, qr/^\s+ok 1 # skip .+/m,  'test skipped');
  like($output, qr/^\s+1\.\.1/m,          'test ran with a plan');

  like($basecheck->_started, qr/^\d+$/, '_started attribute has numeric value');
  is($basecheck->_finished,  undef,     '_finished attribute is undefined');
  is($basecheck->_passed,    1,         '_passed attribute is true');
};

done_testing();
