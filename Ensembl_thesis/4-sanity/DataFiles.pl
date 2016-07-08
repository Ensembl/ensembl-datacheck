
=head1 NAME

  DataFiles - A sanity test (type 4 in the healthcheck system).

=head1 SYNPOSIS

  $ perl DataFiles.pl --species 'homo sapiens' --type 'rnaseq'

=head1 DESCRIPTION

  --species 'species name'    : String (Optional) - Name of the species to test on.
  --type 'database type'      : String (Optional) - Type of the database to test on.
  --config_file               : String (Optional) - location of the config file relative to the working directory. Default
                                is one folder above the working directory.
                                  
  Database type               : rnaseq
  
If no command line input arguments are given, values from the 'config' file in the parent directory of the working directory will be used. 

File names inserted in the data_file table should not have file extensions or spaces
in their names. The data files API will automatically deal with file extensions.

Perl adaptation of the DataFiles.java test.
See: https://github.com/Ensembl/ensj-healthcheck/blob/release/83/src/org/ensembl/healthcheck/testcase/generic/DataFiles.java

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

my $config_file;

GetOptions('config_file:s' => \$config_file);

my $dba = DBUtils::Connect::get_db_adaptor($config_file);

my $species = DBUtils::Connect::get_db_species($dba);

my $database_type = $dba->group();

my $log = Logger->new(
    healthcheck => 'DataFiles',
    species => $species,
    type => $database_type,
);

if(lc($database_type) ne 'rnaseq'){
    $log->message("WARNING: this healthcheck only applies to core databases. Problems in execution/results may arise");
}

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
);

my $result = 1;

#get all the names
my $sql = "SELECT name FROM data_file";

my $names_ref = $helper->execute(
   -SQL => $sql,
);

#An arrayref is returned so we need to iterate over the entries of all the arrays
foreach my $row (@$names_ref){
    foreach my $name (@$row){
        $result &= find_extensions($name);
        $result &= find_spaces($name);
   }
}

$log->result($result);

=head2 find_extensions

  ARG[name]      : String - a entry of the name column of the data_file table
  
  Returntype     : Boolean
  
Checks if the file name doesn't have a file extension

=cut

sub find_extensions{
    my ($name) = @_;

    #look if the name ends in .A-Za-z format
    if($name =~ /\.([A-Za-z]+)$/){
        $log->message("PROBLEM: $name might have a file extension as end.");
        return 0;
    }
    else{
        return 1;
    }
}

=head2 find_spaces

   ARG[name]      : String - a entry of the name column of the data_file table
  
   Returntype     : Boolean 
   
Checks that there are no spaces in the file name.

=cut

sub find_spaces{
    my ($name) = @_;
    
    #look for any spaces in the file name.
    if(index($name, " ") != -1){
        $log->message("PROBLEM: There's a space in filename " . $name);;
        return 0;
    }
    else{
        return 1;
    }
}

