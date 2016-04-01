=head1 NAME

AssemblyNameLength - A sanity test (type 4 in the healthcheck system)

=head1 SYNOPSYS

  $ perl AssemblyNameLength.pl 'Homo sapiens'

=head1 DESCRIPTION

  ARG[Species Name]    : String - Name of the species to test on.
  Database type        : CORE (hardcoded).

A healthcheck that checks that the meta_value for the key
assembly.name in the meta table is not longer than 16 characters.

Perl adaptation of the AssemblyNameLength.java test.
See: https://github.com/Ensembl/ensj-healthcheck/blob/release/83/src/org/ensembl/healthcheck/testcase/generic/AssemblyNameLength.java

=cut

#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Getopt::Long;

use Carp;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use DBUtils::RowCounter;

my $registry = 'Bio::EnsEMBL::Registry';

my $parent_dir = File::Spec->updir;
my $file = $parent_dir . "/config";

my $species;

my $config = do $file;
if(!$config){
    warn "couldn't parse $file: $@" if $@;
    warn "couldn't do $file: $!"    unless defined $config;
    warn "couldn't run $file"       unless $config; 
}
else {
    $registry->load_registry_from_db(
        -host => $config->{'db_registry'}{'host'},
        -user => $config->{'db_registry'}{'user'},
        -port => $config->{'db_registry'}{'port'},
    );
    #if there is command line input use that, else take the config file.
    GetOptions('species:s' => \$species);
    if(!defined $species){
        $species = $config->{'species'};
    }
} 

my $dba = $registry->get_DBAdaptor($species, 'core');

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
);

my $result = 1;

#Check if the assembly name is declared
my $sql = "SELECT COUNT(*) FROM meta WHERE meta_key = 'assembly.name'";

my $rowcount = DBUtils::RowCounter::get_row_count({ 
    helper => $helper,
    sql => $sql,
});

if($rowcount == 0){
    print "PROBLEM: No assembly name declared in meta (core) for $species \n";
    my $result &= 0;   
}
else{
    #assembly name is present. make sure it's length < 16
    my $query_result = $helper->execute(
        -SQL => "SELECT LENGTH(meta_value) FROM meta
                   WHERE meta_key = 'assembly.name'",
    );
    my $assembly_name_length = $query_result->[0][0];

    if($assembly_name_length > 16){
        my $result &= 0;
        print "PROBLEM: assembly name in meta_key found with length > 16 \n";
    }
}

print "$result \n";
        
