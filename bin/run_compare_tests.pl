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

use Bio::EnsEMBL::DataTest::Utils::TestUtils qw/load_tests/;

my $cli_helper = Bio::EnsEMBL::Utils::CliHelper->new();
# get the basic options for connecting to a database server
my $optsd =
  [ @{ $cli_helper->get_dba_opts() }, @{ $cli_helper->get_dba_opts('prev') } ];

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

if ( !$opts->{user} || !$opts->{host} || !$opts->{port} || !$opts->{test}||
!$opts->{prevuser} || !$opts->{prevhost} || !$opts->{prevport} ) {
  pod2usage(1);
}

# load tests from file system
my $tests = [];
for my $test_loc ( @{ $opts->{test} } ) {
  $tests = [ @$tests, @{ load_tests($test_loc) } ];
}

# connect to each database in turn
$logger->info("Connecting to previous DBAs");
my $prev_dbas = {};
for my $dba_args ( @{ $cli_helper->get_dba_args_for_opts($opts,1,'prev') } ) {
  my $dba    = Bio::EnsEMBL::DBSQL::DBAdaptor->new( %{$dba_args} );
  my $dbname = $dba->dbc()->dbname();
  $prev_dbas->{$dbname} = $dba;
}

$logger->info("Connecting to current DBAs");
my $test_results = {};
for my $dba_args ( @{ $cli_helper->get_dba_args_for_opts($opts) } ) {
  my $dba    = Bio::EnsEMBL::DBSQL::DBAdaptor->new( %{$dba_args} );
  my $dbname = $dba->dbc()->dbname();
  $logger->info( "Testing " . $dbname . "/" . $dba->species_id() );
  my $prev_dba = get_prev_dba($prev_dbas,$dbname);
  if(!defined $prev_dba) {
    $logger->warn("Cannot find previous DBA for $dbname");
    next;
  }
  for my $test (@$tests) {
    if ( $test->can("per_species") && $test->per_species() ) {
      $logger->debug( "Per-species test " . $test->name() );
      $logger->info("Running ".$test->name()." on $dbname/".$dba->species_id()." vs ".$prev_dba->dbc()->dbname()."/".$prev_dba->species_id());
      my $res = $test->run($dba, $prev_dba);
      $logger->info($test->name()." ".($res->{pass}==1?"passed":"failed")." for ".$dbname."/".$dba->species_id()." vs ".$prev_dba->dbc()->dbname()."/".$prev_dba->species_id());
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
      $logger->info("Running ".$test->name()." on $dbname vs ".$prev_dba->dbc()->dbname());
      my $res = $test->run($dba, $dba);
      $logger->info($test->name()." ".($res->{pass}==1?"passed":"failed")." for ".$dbname." vs ".$prev_dba->dbc()->dbname());
      $test_results->{ $test->name() }->{$dbname} = $res;
    }
  }
}

print Dumper($test_results);

sub get_prev_dba {
  my ($dbas, $dbname) = @_;
  my $dba;
  (my $db_stem = $dbname) =~ s/(.*_[a-z]+)_\d+_\d+(_\d+)?/$1/;
  $logger->debug("Searching for $dbname via $db_stem");
  while(my ($prev_dbname,$prev_dba) = each %$dbas) {
    if(index($prev_dbname, $db_stem)!=-1) {
      $dba = $prev_dba;
      last;
    }
  }
  return $dba;
}
