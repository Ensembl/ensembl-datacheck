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

use Log::Log4perl qw/:easy/;
use Carp;
use File::Slurp;
use File::Find;
use Data::Dumper;
use Pod::Usage;

use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::CliHelper;

my $cli_helper = Bio::EnsEMBL::Utils::CliHelper->new();
# get the basic options for connecting to a database server
my $optsd =
  [ @{ $cli_helper->get_dba_opts() }, @{ $cli_helper->get_dba_opts('m') } ];

push( @{$optsd}, "test|t:s@" );
push( @{$optsd}, "verbose" );
# process the command line with the supplied options plus a help subroutine
my $opts = $cli_helper->process_args( $optsd, \&pod2usage );

if ( $opts->{verbose} ) {
  Log::Log4perl->easy_init($DEBUG);
}
else {
  Log::Log4perl->easy_init($INFO);
}
my $logger = get_logger();

if ( !$opts->{user} || !$opts->{host} || !$opts->{port} || !$opts->{test} ) {
  pod2usage(1);
}

# load tests from file system
my $tests = [];
for my $test_loc ( @{ $opts->{test} } ) {
  $tests = [ @$tests, @{ load_tests($test_loc) } ];
}

# connect to production db if supplied
if ( defined $opts->{mhost} ) {
  $logger->info("Connecting to production database");
  my ($prod_dba) = @{ $cli_helper->get_dba_for_opts($opts), 'm' };
}

# connect to each database in turn
$logger->info("Connecting to DBAs");
my $test_results = {};
for my $dba_args ( @{ $cli_helper->get_dba_args_for_opts($opts) } ) {
  my $dba    = Bio::EnsEMBL::DBSQL::DBAdaptor->new( %{$dba_args} );
  my $dbname = $dba->dbc()->dbname();
  $logger->info( "Testing " . $dbname . "/" . $dba->species_id() );
  for my $test (@$tests) {
    if ( $test->can("per_species") && $test->per_species() ) {
      $logger->debug( "Per-species test " . $test->name() );
      $logger->info("Running ".$test->name()." on $dbname/">$dba->species_id());
      my $res = $test->run($dba);
      $logger->info($test->name()." ".($res->{pass}==1?"passed":"failed")." for ".$dbname."/".$dba->species_id());
      $test_results->{ $test->name() }->{$dbname}->{ $dba->species_id() } =
        $res;
    }
    else {
      $logger->debug( "Per-db test " . $test->name() );
      # don't repeat tests
      if ( defined $test_results->{ $test->name() }->{$dbname} ) {
        $logger->debug( "Skipping per db test " . $test->name() );
      }
      $logger->debug( "Per-db test " . $test->name() . " not yet seen" );
      $logger->info("Running ".$test->name()." on $dbname");
      my $res = $test->run($dba);
      $logger->info($test->name()." ".($res->{pass}==1?"passed":"failed")." for ".$dbname);
      $test_results->{ $test->name() }->{$dbname} = $res;
    }
  }
}

# load tests from supplied source file/directory
sub load_tests {
  my ($test_loc) = @_;
  $logger->info("Test loc $test_loc");
  my $tests = [];
  if ( -f $test_loc ) {
    push @$tests, read_test($test_loc);
  }
  elsif ( -d $test_loc || -l $test_loc ) {
    $logger->info("Reading tests from $test_loc");
    find( {
        wanted => sub {
          if (m/\.t$/) {
            push @$tests, read_test($_);
          }
        },
        no_chdir => 1,
        follow   => 1 },
      $test_loc );
  }
  else {
    croak("Cannot read test location $test_loc");
  }
  return $tests;
} ## end sub load_tests

# read test from a single file
sub read_test {
  my ($file) = @_;
  $logger->debug("Reading test from $file");
  my $test_str = read_file($file) || croak "Could not read test file $file";
  my $test = eval $test_str;
  if ($@) {
    croak "Could not parse test file $file: $@";
  }
  return $test;
}

# invoke test on a given database
sub test_database {
  my ( $dba, $tests ) = @_;
  return;
}
