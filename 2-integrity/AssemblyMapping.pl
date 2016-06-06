=head1 NAME

  AssemblyMapping - A user-defined integrity test (type 2 in the healthcheck system)

=head1 SYNOPSIS

  $ perl AssemblyMapping.pl --config '../config'

=head1 DESCRIPTION
  --species 'species name'      : String (Optional) - name of the species to check on.
  --type 'database type'        : String (Optional) - name of the database type to test on.
  --config_file                 : String (Optional) - location of the config file relative to the working directory. Default
                                  is one folder above the working directory.
                           
  Database                      : Core

If no command line input arguments are given, values from the 'config' file in the parent directory of the working directory will be used.   
  
Checks if the assembly.mapping values in the meta table are in the right format and if they refer to existing
coordinate systems (name & version).

Perl adaptation of the AssemblyMapping.java test
See: https://github.com/Ensembl/ensj-healthcheck/blob/release/83/src/org/ensembl/healthcheck/testcase/generic/AssemblyMapping.java

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
use DBUtils::MultiSpecies;

my $config_file;

GetOptions('config_file:s' => \$config_file);

my $registry = 'Bio::EnsEMBL::Registry';

my $dba = DBUtils::Connect::get_db_adaptor($config_file);

my $species = DBUtils::Connect::get_db_species($dba);

my $database_type = $dba->group();

my $log = Logger->new(
    healthcheck => 'AssemblyMapping',
    species => $species,
    type => $database_type,
);

if(lc($database_type) ne 'core'){
    $log->message("WARNING: this healthcheck only applies to core databases. Problems in execution will likely arise");
}

my $result = 1;

#finds a pattern of two strings seperated by : or just one string
my $assembly_pattern = qr/([^:]+)(:(.+))?/;

my @species_names = @ { DBUtils::MultiSpecies::get_all_species_in_registry($registry) };


my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
);

#get the id(s) that belongs to the database
my @ids = @ { DBUtils::MultiSpecies::get_multi_species_ids($helper) };

if(@ids == 0){
    $log->message("No species id found in the database (check the meta table)");
    $result &= 0;
}

foreach my $id_ref (@ids){
    my $id = $id_ref->[0];

    my $cs_sql = "SELECT name, version FROM coord_system "
                  . "WHERE species_id = $id";
  
    my $cs_result = $helper->execute(
        -SQL => $cs_sql,
    );       
       
    my $cs_result_string;
    my $cs_name;
    my $cs_version;
    
    if($#$cs_result < 1){
        $log->message("PROBLEM: No entries in the coord_system for species_id $id");
        $result &= 0;
        next;
    }
    
    #make a cs_result_string containing all the name version pairs. this way we can use index to look for pairs later on.
    for(my $i = 0; $i <= $#$cs_result; $i++){
        $cs_name = ($cs_result->[$i][0]);
        #the sql helper returns NULLs as undefined which upsets Perl, so we change them back to NULLs.
        if(defined $cs_result->[$i][1]){
            $cs_version = ($cs_result->[$i][1]);
        }
        else{
            $cs_version = 'NULL';
        }
            
        $cs_result_string .= $cs_name . $cs_version
    }
        
    my $assembly_map_sql = "SELECT meta_value FROM meta "
                            . "WHERE meta_key = 'assembly.mapping' "
                            . "AND species_id = $id";
        
            
    my $assembly_map_result = $helper->execute(
         -SQL => $assembly_map_sql,
    );

    #each meta_value that represents an assembly mapping needs to match a certain format and needs to be used in the coord_system table
    for(my $i = 0; $i <= $#$assembly_map_result; $i++){
        my $assembly_map = $assembly_map_result->[$i][0];

        if(!defined $assembly_map || $assembly_map eq ''){
            $log->message("PROBLEM: An assembly.mapping entry in the meta table has meta_value NULL or an empty string");
            $result &= 0;
            next;
        }
        
        #split the mapping on | or #
        my @map_elements = split(/[|#]/, $assembly_map);
        #and for each element of the split check some stuff...
        foreach my $map_element (@map_elements){
   
           #see if it matches the right format
           if($map_element =~ $assembly_pattern){
               my @reg_exp_groups = $map_element =~ $assembly_pattern;
                    
               my $name = $reg_exp_groups[0];
               my $version = '';
               if(defined $reg_exp_groups[2]){
                   $version = $reg_exp_groups[2];
               }
                    
               #look if the name is in the coordinate system string we created earlier
               if(index($cs_result_string, $name) == -1){
                   $log->message("PROBLEM: No coordinate system named $name found in $species for $assembly_map");
                   $result &= 0;
               }
               else{
                   #look for the combination name and version in the coordinate system string
                   if(index($cs_result_string, $name . $version) == -1){
                       $log->message("PROBLEM: No coordinate system named $name with version $version "
                                . "found in $species for $assembly_map");
                       $result &= 0;
                   }
                   else{
                       #uncomment this if you want to see the species being tested.
                       #$log->message("OK");
                   }
                }         
           }
           else{
               $log->message("PROBLEM: Assembly mapping element $map_element from $assembly_map "
                          . "in $species does not match the expected pattern $assembly_pattern");
                $result &= 0;
            } 
        }
    }             
}

$log->result($result);


