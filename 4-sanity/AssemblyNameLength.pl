=head1 NAME

AssemblyNameLength - A sanity test (type 4 in the healthcheck system)

=head1 SYNOPSYS

  $ perl AssemblyNameLength.pl --species 'homo sapiens' --type 'core'

=head1 DESCRIPTION

  --species 'species name'   : String (Optional) - Name of the species to test on.
  --type 'database type'     : String (Optional) - Database type to test on
  --config_file              : String (Optional) - location of the config file relative to the working directory. Default
                               is one folder above the working directory.
  
  Database type              : Core
  
If no command line input arguments are given, values from the 'config' file in the main directory will be used.

A healthcheck that checks that the meta_value for the key
assembly.name in the meta table is not longer than 16 characters.

Perl adaptation of the AssemblyNameLength.java test.
See: https://github.com/Ensembl/ensj-healthcheck/blob/release/83/src/org/ensembl/healthcheck/testcase/generic/AssemblyNameLength.java

=cut

#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Getopt::Long qw(:config pass_through);

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use Logger;
use DBUtils::Connect;
use DBUtils::RowCounter;

my $config_file;

GetOptions('config_file:s' => \$config_file);

my $dba = DBUtils::Connect::get_db_adaptor($config_file);

my $species = DBUtils::Connect::get_db_species($dba);

my $database_type = $dba->group();

my $log = Logger->new(
    healthcheck => 'AssemblyNameLength',
    species => $species,
    type => $database_type,
);

if(lc($database_type) ne 'core'){
    $log->message("WARNING: this healthcheck only applies to core databases. Problems in execution/results may arise");
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
    $result &= 0;   
}
else{
    #assembly name is present. make sure it's length < 16
    my $query_result = $helper->execute(
        -SQL => "SELECT LENGTH(meta_value) FROM meta
                   WHERE meta_key = 'assembly.name'",
    );
    my $assembly_name_length = $query_result->[0][0];

    if($assembly_name_length > 16){
        $result &= 0;
        $log->message("PROBLEM: assembly.name meta_value found with length > 16");
    }
}

$log->result($result);
        
