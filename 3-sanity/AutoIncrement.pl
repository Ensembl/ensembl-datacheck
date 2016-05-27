
=head1 NAME

  AutoIncrement - A sanity test (type 3 in the healthcheck system).

=head1 SYNOPSIS

  $ perl AutoIncrement.pl --species 'homo sapiens' --type 'core'

=head1 DESCRIPTION

  --species 'species name'     : String (optional) - Name of the species to test on.
  --type 'database type'       : String (optional) - Database type to test on.
  --config_file                : String (Optional) - location of the config file relative to the working directory. Default
                                 is one folder above the working directory.

  Database type                : Generic databases (core, vega, cdna, otherfeatures, rnaseq)
  
If no command line input arguments are given, values from the 'config' file in the main directory will be used.

Certain columns in the core tables should have the AUTO_INCREMENT flag set. This healthchecks retrieves
meta information for those columns to check that this is the case.

Perl adaptation of the AutoIncrement.java test.
See: https://github.com/Ensembl/ensj-healthcheck/blob/bb8a7c3852206049087c52c5b517766eef555c7d/src/org/ensembl/healthcheck/testcase/generic/AutoIncrement.java
 
=cut

#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use DBUtils::Connect;

use File::Spec;
use Getopt::Long qw(:config pass_through);

use Input::AutoIncrement;

use Logger;


my $config_file;

GetOptions('config_file:s' => \$config_file);

my $dba = DBUtils::Connect::get_db_adaptor($config_file);

my $species = DBUtils::Connect::get_db_species($dba);
my $database_type = $dba->group();

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
   -DB_CONNECTION => $dba->dbc()
);

my $log = Logger->new({
    healthcheck => 'AutoIncrement',
    type => $database_type,
    species => $species,    
});
    

my $result = 1;

#These are all the columns that should have autoincrement set.
my @columns = @Input::AutoIncrement::AI_columns;

#Get the database name. We need this for our query.
my $dbname = ($dba->dbc())->dbname();

foreach my $part (@columns){
    #split to get both table and column names.
    my @tablecolumn = split(/\./, $part);
    my $table = $tablecolumn[0];
    my $column = $tablecolumn[1];

    #this query will return column info, including whether it is auto incremented.
    my $sql = "SHOW COLUMNS FROM " . $table . " IN " . $dbname . " WHERE field = '" . $column . "'";

    my $query_result = $helper->execute(
        -SQL => $sql,
    );

    foreach my $nested_array (@$query_result){
        #loook for 'aut_increment'  in results and push it in an array.	    
        my @auto_increment;

                foreach my $cell (@$nested_array){
                    if(defined $cell){
                        if($cell eq 'auto_increment'){
                            push @auto_increment, $cell;
                        }
                     }
                }

            #... if the array is empty, autoincrement has not been declared for this column!
            if(!@auto_increment){
                $log->message("PROBLEM: " . $table . "." . $column . "  is not set to autoincrement!");
                $result &= 0;
            }
            
    }
       
}

#print this for now.
$log->result($result);

