#!/usr/bin/env perl
use warnings;
use strict;

use Log::Log4perl qw/:easy/;
use Carp;
use File::Slurp;
use File::Find;
use Data::Dumper;

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
  $tests = [ $tests, load_tests($test_loc) ];
}

# connect to production db if supplied
if ( defined $opts->{mhost} ) {
  $logger->info("Connecting to production database");
  my ($prod_dba) = @{ $cli_helper->get_dba_for_opts($opts), 'm' };
}

# connect to each database in turn
$logger->info("Connecting to DBAs");
for my $dba_args ( @{ $cli_helper->get_dba_args_for_opts($opts) } ) {
  my $dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new( %{$dba_args} );
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
          print "$File::Find::name\n";
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
}

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
