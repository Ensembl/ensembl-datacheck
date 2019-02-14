# Copyright [2018-2019] EMBL-European Bioinformatics Institute
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
use feature 'say';

use Bio::EnsEMBL::DataCheck::Manager;
use Bio::EnsEMBL::Test::MultiTestDB;

use FindBin; FindBin::again();
use JSON;
use Path::Tiny;
use Test::Exception;
use Test::More;

my $test_db_dir = $FindBin::Bin;
my %db_types    = (
                    collection => ['core'],
                    drosophila_melanogaster => ['core'],
                    homo_sapiens => ['core', 'funcgen', 'variation'],
                  );
my $db_type     = 'core';
my $dba_type    = 'Bio::EnsEMBL::DBSQL::DBAdaptor';

my $datacheck_dir = "$FindBin::Bin/TestChecks";
my $index_file    = "$FindBin::Bin/index.json";

my $module = 'Bio::EnsEMBL::DataCheck::Manager';

diag('Attributes');
can_ok($module, qw(datacheck_dir index_file config_file names patterns groups datacheck_types history_file output_file));

diag('Methods');
can_ok($module, qw(load_config load_checks filter run_checks read_index write_index read_history write_history));

# Need to move the default config file, if it exists, so that we
# can test its absence/presence properly.
my $default_config_file = $FindBin::Bin;
$default_config_file =~ s!t$!config.json!;
if (-e $default_config_file) {
  path($default_config_file)->move("$default_config_file.tmp");
}

# As well as being a nice way to encapsulate sets of tests, the use of
# subtests here is necessary, because the behaviour we are testing
# involves running tests, and we need to isolate that from the reports
# of this test (i.e. Manager.t).

subtest 'Default attributes', sub {
  my $manager = $module->new();

  like($manager->datacheck_dir, qr!lib/Bio/EnsEMBL/DataCheck/Checks!,     'Default datacheck_dir correct');
  like($manager->index_file,    qr!lib/Bio/EnsEMBL/DataCheck/index.json!, 'Default index_file correct');
  is($manager->config_file,     undef, 'Default config_file correct (undefined)');
  is($manager->history_file,    undef, 'Default history_file correct (undefined)');
  is($manager->output_file,     undef, 'Default output_file correct (undefined)');
  is_deeply($manager->names,    [], 'Default names correct (empty list)');
  is_deeply($manager->patterns, [], 'Default patterns correct (empty list)');
  is_deeply($manager->groups,   [], 'Default groups correct (empty list)');
  is_deeply($manager->datacheck_types, [], 'Default datacheck_types correct (empty list)');
};

subtest 'Config file', sub {
  my $manager = $module->new(
    config_file => '/oops/file/does/not/exist',
  );

  throws_ok(
    sub { $manager->load_config() },
    qr/Config file does not exist/, 'Check for existence of config file');

  my $config = {
    registry_file  => 'registry_file_from_config',
    data_file_path =>  'data_file_path_from_config',
  };
  my $json = JSON->new->pretty->encode($config);
  my $config_file = Path::Tiny->tempfile();
  $config_file->spew($json);

  $manager->config_file($config_file->stringify);

  my %params = (
    registry_file  => 'registry_file_from_param',
    old_server_uri => 'old_server_uri_from_param',
  );

  my %loaded = $manager->load_config(%params);

  is($loaded{data_file_path}, 'data_file_path_from_config', 'Parameter loaded from config file');
  is($loaded{old_server_uri}, 'old_server_uri_from_param', 'Explicit parameter loaded');
  is($loaded{registry_file},  'registry_file_from_param', 'Explicit parameters overwrite config file');
};

subtest 'TestChecks directory', sub {
  my $manager = $module->new(
    datacheck_dir => $datacheck_dir,
    index_file    => $index_file,
  );

  like($manager->datacheck_dir, qr!t/TestChecks!, 'TestChecks datacheck_dir correct');
  like($manager->index_file,    qr!t/index.json!, 'TestChecks index_file correct');

  my $datachecks = $manager->load_checks();

  is(scalar(@$datachecks), 8, 'Loaded eight datachecks');
  foreach (@$datachecks) {
    isa_ok($_, 'Bio::EnsEMBL::DataCheck::BaseCheck');
    is($_->_started,  undef, '_started attribute undefined for '.$_->name);
    is($_->_finished, undef, '_finished attribute undefined for '.$_->name);
    is($_->_passed,   undef, '_passed attribute undefined for '.$_->name);
  }
};

subtest 'Filter names', sub {
  my @names = ('BaseCheck_1', 'BaseCheck_3');
  my $manager = $module->new(
    datacheck_dir => $datacheck_dir,
    index_file    => $index_file,
    names         => \@names,
  );

  my $datachecks = $manager->load_checks();
  is(scalar(@$datachecks), 2, 'Loaded two datachecks');
  my %datacheck_names = map {$_->name => 1} @$datachecks;
  foreach (@names) {
    ok(exists $datacheck_names{$_}, "$_ name matches $_");
  }
};

subtest 'Filter patterns', sub {
  my $pattern = 'BaseCheck';
  my $manager = $module->new(
    datacheck_dir => $datacheck_dir,
    index_file    => $index_file,
    patterns      => [$pattern],
  );

  my $datachecks = $manager->load_checks();
  is(scalar(@$datachecks), 3, 'Loaded three datachecks');
  foreach (@$datachecks) {
    like($_->name, qr/$pattern/, $_->name." name matches pattern '$pattern'");
  }

  $pattern = 'failing';
  $manager->patterns([$pattern]);

  $datachecks = $manager->load_checks();
  is(scalar(@$datachecks), 2, 'Loaded two datachecks');
  foreach (@$datachecks) {
    like($_->description, qr/$pattern/i, $_->name." description matches pattern '$pattern'");
  }
};

subtest 'Filter groups', sub {
  my @groups = ('skipped');
  my $manager = $module->new(
    datacheck_dir => $datacheck_dir,
    index_file    => $index_file,
    groups        => \@groups,
  );

  my $datachecks = $manager->load_checks();
  is(scalar(@$datachecks), 1, 'Loaded one datacheck');
  foreach my $datacheck (@$datachecks) {
    my %datacheck_groups = map {$_ => 1} @{$datacheck->groups};
    foreach (@groups) {
      ok(exists $datacheck_groups{$_}, $datacheck->name." group matches '$_'");
    }
  }

  @groups = ('base', 'skipped');
  $manager->groups(\@groups);

  $datachecks = $manager->load_checks();
  is(scalar(@$datachecks), 2, 'Loaded two datachecks');
  foreach my $datacheck (@$datachecks) {
    my $match = 0;
    my %datacheck_groups = map {$_ => 1} @{$datacheck->groups};
    foreach (@groups) {
      $match = 1 if exists $datacheck_groups{$_};
    }
    ok($match, $datacheck->name." group matches one of: ".join(', ', @groups));
  }
};

subtest 'Filter datacheck type', sub {
  my $datacheck_type = 'critical';
  my $manager = $module->new(
    datacheck_dir   => $datacheck_dir,
    index_file      => $index_file,
    datacheck_types => [$datacheck_type],
  );

  my $datachecks = $manager->load_checks();
  is(scalar(@$datachecks), 7, 'Loaded seven datachecks');
  my %datacheck_names = map {$_->name => 1} @$datachecks;
  foreach (@$datachecks) {
    is($_->datacheck_type, $datacheck_type, $_->name." datacheck type matches '$datacheck_type'");
  }
};

subtest 'Write index (BaseCheck)', sub {
  my $manager = $module->new(
    datacheck_dir   => $datacheck_dir,
    index_file      => $index_file,
    overwrite_files => 0,
  );

  throws_ok(
    sub { $manager->write_index() },
    qr/exists, and will not be overwritten/, 'index_file not overwritten');
};

subtest 'Read history file (BaseCheck)', sub {
  # Note that the $test_history hash does not include details for all
  # test datachecks, and also has a superfluous result, in order to
  # test partially matching history_files.
  my $test_history = {
    BaseCheck_0 => {
      passed   => 1,
      started  => 1520338725,
      finished => 1520338726,
    },
    BaseCheck_2 => {
      passed   => 0,
      started  => 1520338727,
      finished => 1520338728,
    },
    BaseCheck_3 => {
      passed   => 1,
      started  => 1520338729,
      finished => undef,
    },
  };

  my $json = JSON->new->pretty->encode($test_history);
  my $history_file = Path::Tiny->tempfile();
  $history_file->spew($json);

  my $manager = $module->new(
    datacheck_dir => $datacheck_dir,
    index_file    => $index_file,
    history_file  => $history_file->stringify,
    names         => ['BaseCheck_1', 'BaseCheck_2', 'BaseCheck_3'],
  );

  my $datachecks = $manager->load_checks();
  foreach (@$datachecks) {
    if ($_->name eq 'BaseCheck_1') {
      is($_->_started,  undef, '_started attribute is undefined for BaseCheck_1');
      is($_->_finished, undef, '_finished attribute is undefined for BaseCheck_1');
      is($_->_passed,   undef, '_passed attribute is undefined for BaseCheck_1');

    } elsif ($_->name eq 'BaseCheck_2') {
      is($_->_started,  1520338727, '_started attribute correct for BaseCheck_2');
      is($_->_finished, 1520338728, '_finished attribute correct for BaseCheck_2');
      is($_->_passed,   0, '_passed attribute correct for BaseCheck_2');

    } elsif ($_->name eq 'BaseCheck_3') {
      is($_->_started,  1520338729, '_started attribute correct for BaseCheck_3');
      is($_->_finished, undef,      '_finished attribute correct for BaseCheck_3');
      is($_->_passed,   1, '_passed attribute correct for BaseCheck_3');
    }
  }
};

subtest 'Write history file (BaseCheck)', sub {
  my $history_file = Path::Tiny->tempfile();
  my $manager = $module->new(
    datacheck_dir => $datacheck_dir,
    index_file    => $index_file,
    patterns      => ['BaseCheck'],
  );

  my @attributes = sort ('passed', 'started', 'finished');

  my $before = time();
  sleep(2);

  my $datachecks = $manager->load_checks();
  foreach (@$datachecks) {
    $_->run;
  }

  sleep(2);
  my $after = time();

  throws_ok(
    sub { $manager->write_history($datachecks) },
    qr/Path to history file not specified/, 'check for history file path');

  $manager->history_file($history_file->stringify);

  $manager->write_history($datachecks);

  my $json = $history_file->slurp;
  my $history = JSON->new->decode($json);

  foreach (@$datachecks) {
    ok(exists $$history{$_->name}, 'Results written for '.$_->name);

    my @datacheck_attributes = sort keys %{$$history{$_->name}};
    is_deeply(\@datacheck_attributes, \@attributes, 'Expected attributes exist for '.$_->name);

    if (exists $$history{$_->name}{started}) {
      my $started = $$history{$_->name}{started};
      ok($before < $started && $after > $started, 'Started within expected range for '.$_->name);
    }

    if (exists $$history{$_->name}{finished}) {
      my $finished = $$history{$_->name}{finished};
      if (defined $finished) {
        ok($before < $finished && $after > $finished, 'Finished within expected range for '.$_->name);
      }
    }
  }
};

subtest 'Read and write history file', sub {
  # Note that the $test_history hash does not include details for all
  # test datachecks, and also has a superfluous result, in order to
  # test partially matching history_files.
  my $test_history = {
    BaseCheck_0 => {
      passed   => 1,
      started  => 1520338725,
      finished => 1520338726,
    },
    BaseCheck_2 => {
      passed   => 0,
      started  => 1520338727,
      finished => 1520338728,
    },
    BaseCheck_3 => {
      passed   => 1,
      started  => 1520338729,
      finished => undef,
    },
  };

  my $json = JSON->new->pretty->encode($test_history);
  my $history_file = Path::Tiny->tempfile();
  $history_file->spew($json);

  # We need to redirect test output to a file, otherwise it gets muddled
  # with the output from this .t file, and confuses the test harness.
  my $output_file = Path::Tiny->tempfile();

  my $manager = $module->new(
    datacheck_dir   => $datacheck_dir,
    index_file      => $index_file,
    history_file    => $history_file->stringify,
    output_file     => $output_file->stringify,
    overwrite_files => 0,
    names           => ['BaseCheck_1', 'BaseCheck_3'],
  );

  my $datachecks = $manager->load_checks();
  foreach (@$datachecks) {
    $_->run;
  }

  throws_ok(
    sub { $manager->run_checks() },
    qr/exists, and will not be overwritten/, 'output_file not overwritten');

  throws_ok(
    sub { $manager->write_history($datachecks) },
    qr/exists, and will not be overwritten/, 'history_file not overwritten');

  $manager->overwrite_files(1);
  my $history = $manager->write_history($datachecks);

  # We want to have the same details for BaseCheck_0 and BaseCheck_2,
  # because we have not run those tests. BaseCheck_1 details should now
  # be there, and BaseCheck_3 should have been updated.
  is(keys %{$history}, 4, 'Correct number of datachecks');
  is($$history{'BaseCheck_0'}{'started'}, 1520338725, 'Results for BaseCheck_0 persist');
  ok(exists $$history{'BaseCheck_1'}{'started'}, 'Results for BaseCheck_1 added');
  is($$history{'BaseCheck_2'}{'started'}, 1520338727, 'Results for BaseCheck_2 persist');
  cmp_ok($$history{'BaseCheck_3'}{'started'}, '>', 1520338729, 'Results for BaseCheck_3 updated');
};

subtest 'Run datachecks (BaseCheck)', sub {
  # We need to redirect test output to a file, otherwise it gets muddled
  # with the output from this .t file, and confuses the test harness.
  my $output_file = Path::Tiny->tempfile();

  my $before = time();
  sleep(2);

  my $manager = $module->new(
    datacheck_dir => $datacheck_dir,
    index_file    => $index_file,
    output_file   => $output_file->stringify,
    names         => ['BaseCheck_1', 'BaseCheck_3'],
  );

  my ($datachecks, $aggregator) = $manager->run_checks();

  sleep(2);
  my $after = time();

  foreach (@$datachecks) {
    like($_->_passed, qr/^[01]$/, '_passed attribute has valid value for '.$_->name);
    ok($before < $_->_started && $after > $_->_started, '_started attribute within expected range for '.$_->name);
    if (defined $_->_finished) {
      ok($before < $_->_finished && $after > $_->_finished, '_finished attribute within expected range for '.$_->name);
    }
  }
};

foreach my $species (keys %db_types) {
  my $testdb = Bio::EnsEMBL::Test::MultiTestDB->new($species, $test_db_dir);

  foreach my $db_type (@{ $db_types{$species} }) {
    my $dba    = $testdb->get_DBAdaptor($db_type);

    subtest "Run datachecks (DbCheck, $species, $db_type)", sub {
      # We need to redirect test output to a file, otherwise it gets muddled
      # with the output from this .t file, and confuses the test harness.
      my $output_file = Path::Tiny->tempfile();

      my $before = time();
      sleep(2);

      my $manager = $module->new(
        datacheck_dir => $datacheck_dir,
        index_file    => $index_file,
        output_file   => $output_file->stringify,
        names         => ['DbCheck_1', 'DbCheck_3'],
      );

      my ($datachecks, $aggregator) = $manager->run_checks(dba => $dba);

      sleep(2);
      my $after = time();

      foreach (@$datachecks) {
        like($_->_passed, qr/^[01]$/, '_passed attribute has valid value for '.$_->name);
        ok($before < $_->_started && $after > $_->_started, '_started attribute within expected range for '.$_->name);
        if (defined $_->_finished) {
          ok($before < $_->_finished && $after > $_->_finished, '_finished attribute within expected range for '.$_->name);
        }
      }
    };

    subtest "Read and write history file (DbCheck, $species, $db_type)", sub {
      my $history_file = Path::Tiny->tempfile();
      my $output_file  = Path::Tiny->tempfile();

      my $manager = $module->new(
        datacheck_dir => $datacheck_dir,
        index_file    => $index_file,
        history_file  => $history_file->stringify,
        output_file   => $output_file->stringify,
        patterns      => ['DbCheck'],
      );

      my @attributes = sort ('passed', 'started', 'finished');

      my $before = time();
      sleep(2);

      my ($datachecks, undef) = $manager->run_checks(dba => $dba);

      sleep(2);
      my $after = time();

      my $json = $history_file->slurp;
      my $history = JSON->new->decode($json);

      my $dbserver = $dba->dbc->host . ':' . $dba->dbc->port;
      my $dbname   = $dba->dbc->dbname;
      my $db_history_species = $$history{$dbserver}{$dbname}{'1'};
      my $db_history_all     = $$history{$dbserver}{$dbname}{'all'};

      foreach (@$datachecks) {
        my $db_history;
        if ($_->name eq 'DbCheck_4') {
          $db_history = $db_history_all;
        } else {
          $db_history = $db_history_species;
        }

        ok(exists $$db_history{$_->name}, 'Results written for '.$_->name);

        my @datacheck_attributes = sort keys %{$$db_history{$_->name}};
        is_deeply(\@datacheck_attributes, \@attributes, 'Expected attributes exist for '.$_->name);

        if (exists $$db_history{$_->name}{started}) {
          my $started = $$db_history{$_->name}{started};
          ok($before < $started && $after > $started, 'Started within expected range for '.$_->name);
        }

        if (exists $$db_history{$_->name}{finished}) {
          my $finished = $$db_history{$_->name}{finished};
          if (defined $finished) {
            ok($before < $finished && $after > $finished, 'Finished within expected range for '.$_->name);
          }
        }
      }

      # The tests that are run are Test::More tests. Running them within a test
      # is a bit confusing. To simulate a proper test of the tests, need to reset
      # the Test::More framework.
      Test::More->builder->reset();

      ($datachecks, undef) = $manager->run_checks(dba => $dba);

      # Should have 4 skipped checks and one failed one,
      # if the history file was read correctly.
      my ($skipped, $failed) = (0, 0);
      foreach (@$datachecks) {
        $skipped++ if $_->_passed && ! defined $_->_finished;
        $failed++  if ! $_->_passed;
      }
      is($skipped, 4, 'Correct number of skipped tests');
      is($failed,  1, 'Correct number of failed tests');
    };
  }
}

# Reinstate config file, if necessary.
if (-e "$default_config_file.tmp") {
  path("$default_config_file.tmp")->move($default_config_file);
}

done_testing();
