=head1 NAME

  AssemblyMapping - A user-defined integrity test (type 2 in the healthcheck system)

=head1 SYNOPSIS

  $ perl AssemblyMapping.pl 0

=head1 DESCRIPTION

  ARG[ignore_contigs]    : Boolean - do not warn for contig mappings that do not match the format.

  Database               : Core

######NEEDS REVISION#####
Checks if the assembly.mapping values in the meta table are the right format and if they refer to existing
coordinate systems (name & version).

Perl adaptation of the AssemblyMapping.java test
See: https://github.com/Ensembl/ensj-healthcheck/blob/release/83/src/org/ensembl/healthcheck/testcase/generic/AssemblyMapping.java

=cut

#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Getopt::Long;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use DBUtils::MultiSpecies;

#NEEDS REVISION ANYWAY SO LEAVE THIS FOR NOW
#contigs come up as mistakes a lot, but they're probably not wrong at all. 
my $ignore_contigs = $ARGV[0];

my $registry = 'Bio::EnsEMBL::Registry';

my $parent_dir = File::Spec->updir;
my $file = $parent_dir. "/config";

my $config = do $file;
if(!$config){
    warn "couldn't parse $file: $@" if $@;
    warn "couldn't do $file: $!"    unless defined $config;
    warn "couldn't run $file"       unless $config;
}
else{
    $registry->load_registry_from_db(
           -host => $config->{'db_registry'}{'host'},
           -user => $config->{'db_registry'}{'user'},
           -port => $config->{'db_registry'}{'port'},
    );
}

my $result = 1;

#finds a pattern with two strings seperated by :
my $assembly_pattern = qr/([^:]+)(:(.+))?/;

my @species_names = @ { DBUtils::MultiSpecies::get_all_species_in_registry($registry) };

#use this if you want to tests things in the code.
#my @species_names = ('homo sapiens');

foreach my $species_name (@species_names){
    print "$species_name \n";

    #only applies to core databases
    my $dba = $registry->get_DBAdaptor($species_name, 'core');

    my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
    );

    #get the id(s) that belongs to the database
    my @ids = @ { DBUtils::MultiSpecies::get_multi_species_ids($helper) };
    foreach my $id_ref (@ids){
        my $id = $id_ref->[0];

        my $cs_sql = "SELECT name, version FROM coord_system
                         WHERE species_id = $id";

        my $assembly_map_sql = "SELECT meta_value FROM meta
                                   WHERE meta_key = 'assembly.mapping'
                                   AND species_id = $id";

        my $cs_result = $helper->execute(
            -SQL => $cs_sql,
        );

       
        my $cs_result_string;
        my $cs_name;
        my $cs_version;
        #make a string containing all the name version pairs. this way we can use index and our life will be easier :)
        for(my $i = 0; $i <= $#$cs_result; $i++){
            $cs_name = ($cs_result->[$i][0]);
            if(defined $cs_result->[$i][1]){
                $cs_version = ($cs_result->[$i][1]);
            }
            else{
               $cs_version = 'NULL';
            }
            
            $cs_result_string .= $cs_name . $cs_version
        }

        print "$cs_result_string \n";
            
        my $assembly_map_result = $helper->execute(
            -SQL => $assembly_map_sql,
        );

        #iterate over each assembly mapping cell
        for(my $i = 0; $i <= $#$assembly_map_result; $i++){
            my $assembly_map = $assembly_map_result->[$i][0];

            #split the mapping on | or #
            my @map_elements = split(/[|#]/, $assembly_map);
            #and for each element of the split check some stuff...
            foreach my $map_element (@map_elements){
                
                #contig returns a lot of errors
                if($ignore_contigs){
                    if($map_element eq 'contig'){
                        next;
                    }
                }    
                #see if it matches the right format
                my @reg_exp_groups = $map_element =~ $assembly_pattern;
                #it needs to return a result and the result needs to contain 3 groups.
                if(@reg_exp_groups && (defined $reg_exp_groups[1] && defined $reg_exp_groups[2])){
                    #grab the coordinate system and version from the mapping                    
                    my $name = $reg_exp_groups[0];
                    my $version = $reg_exp_groups[2];
                    
                    #look if the name is in the coordinate system string we created earlier
                    if(index($cs_result_string, $name) == -1){
                        print "PROBLEM: No coordinate system named $name found in $species_name for $assembly_map \n";
                        $result = 0;
                    }
                    else{
                        #look for the combination name and version in the coordinate system string
                        if(index($cs_result_string, $name . $version) == -1){
                            print "PROBLEM: No coordinate system named $name with version $version "
                                  . "found in $species_name for $assembly_map \n";
                            $result = 0;
                        }
                        else{
                            print "OK \n";
                        }
                    }
                
                }
                else{
                    print "PROBLEM: Assembly mapping element $map_element from $assembly_map "
                          . "in $species_name does not match the expected pattern $assembly_pattern \n";
                    $result = 0;
                } 
            }
        }
             
    }
    #makes output easier to read
    print "\n";

}

print "$result \n";


