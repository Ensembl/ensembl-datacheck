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

use Carp;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use DBUtils::RowCounter;

#Follows the old AssemblyNameLength test

#finding species like this is temporary (probably).
my $species = $ARGV[0];
 
my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
	-host => 'ensembldb.ensembl.org',
	-user => 'anonymous',
	-port => 3306,
);

my $dba = $registry->get_DBAdaptor($species, 'core');

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
);

#Check if the assembly name is declared
my $sql = "SELECT COUNT(*) FROM meta WHERE meta_key = 'assembly.name'";

my $rowcount = DBUtils::RowCounter::get_row_count({ 
    helper => $helper,
    sql => $sql,
});

if($rowcount == 0){
    #insert sensible error message
    #return false (or whatever you're going to use to do results) 
    croak "BAD TABLE!!!";   
}
else{
    #assembly name is present. make sure it's length < 16
    my $query_result = $helper->execute(
        -SQL => "SELECT LENGTH(meta_value) FROM meta
                   WHERE meta_key = 'assembly.name'",
    );
    my $assembly_name_length = $query_result->[0][0];

    if($assembly_name_length > 16){
        #insert sensible error message
        #return false (or whatever you're going to use to do results)
        croak "BAD ASSEMBLY NAME!!!";
    }
}

print "SUCCESS:D \n";
#everything went well :)
#return true (or whatever you're going to use to do results)
        
