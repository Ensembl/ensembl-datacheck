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

use Logger;
use DBUtils::Connect;
use DBUtils::RowCounter;

my $dba = DBUtils::Connect::get_db_adaptor();

my $species = DBUtils::Connect::get_db_species($dba);

my $database_type = $dba->group();

my $log = Logger->new(
    healthcheck => 'AssemblyNameLength',
    species => $species,
    type => $database_type,
);

if(lc($database_type) ne 'core'){
    $log->message("WARNING: this healthcheck only applies to core databases. Problems in execution will likely arise");
}

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
    $log->message("PROBLEM: No assembly name declared in meta (core) for $species");
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
        $log->message("PROBLEM: assembly name in meta_key found with length > 16");
    }
}

$log->result($result);
        
