=head1 NAME

  SeqRegionCoordsystem - A user-defined integrity test (type 2 in the healthcheck system)

=head1 SYNOPSYS

  $ perl SeqRegionCoordSystem.pl --species 'homo sapiens' --type 'core'

=head1 DESCRIPTION

  --species 'species name'       : String (Optional) - Name of the species to test on*.
  --type 'database type'         : String (Optional) - Database type to test on.
  --config_file                  : String (Optional) - location of the config file relative to the working directory. Default
                                   is one folder above the working directory.
  
  Database type                  : Generic databases (core, vega, cdna, otherfeatures, rnaseq)
  
If no command line input arguments are given, values from the 'config' file in the main directory will be used.

The SeqRegionCoordsystem test looks for sequence regions in the core database of the species 
with identical names but different coordinate systems. This is done by the check_names function. 
It also checks that sequences with identical names and different coordinate systems are the
same length. This is done by the check_lengths function.
NOTE: These two tests are contradictory for the CORE database test: check_lengths function 
is not needed since there should not be any identically named sequences anyway.

*If you want to check a multispecies database, put the name of one of the species in that database.
The healthcheck will retrieve all the other species from the database and test them as well.

Perl adaptation of the SeqRegionCoordSystem.java test.
See: https://github.com/Ensembl/ensj-healthcheck/blob/release/83/src/org/ensembl/healthcheck/testcase/generic/SeqRegionCoordSystem.java

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
use DBUtils::MultiSpecies;

my $config_file;

GetOptions('config_file:s' => \$config_file);

my $dba = DBUtils::Connect::get_db_adaptor($config_file);

my $species = DBUtils::Connect::get_db_species($dba);
my $database_type = $dba->group();

my $log = Logger->new(
    healthcheck => 'SeqRegionCoordSystem',
    species => $species,
    type => $database_type,
);

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
);

my $result = 1;

#get all the distinct species_ids...for single species databases this is just one
my $species_ids = DBUtils::MultiSpecies::get_multi_species_ids($helper);

if((scalar @{ $species_ids }) > 1){
    $log->message("Multispecies database detected");
}
 
#...and iterate over them to run the test on each species.
foreach my $species_id (@$species_ids){
    foreach my $id (@$species_id){

        $log->message("Checking species by ID: $id");
        
        if(lc($database_type) eq 'core'){
            $result &= check_names($id, $helper, $log);
        }
        $result &= check_lengths($id, $helper, $log);
        }      
}

$log->result($result);

=head2 check_names
    
  ARG[species_id]    : Int - species_id from meta table of the species being checked

  Returntype         : Boolean (0/1)

A SQL query returns the number of instances (=rows) where two sequences have the same
name but different coordinate systems for the same species_id. This should not happen
in core databases, so if any rows are returned it points to a mistake.

=cut

sub check_names{
    my ($species_id, $helper, $log) = @_;

    my $names_result = 1;
    
    

    my $sql = "SELECT coord_system_id FROM coord_system
                  WHERE species_id = $species_id";

    my $coord_systems = $helper->execute(
        -SQL => $sql,
    );

    #loop over the arrayref. Compares every possible id pair.
    for(my $i = 0; $i <= $#$coord_systems; $i++){
        my $id_1 = $coord_systems->[$i][0];
        for(my $j = $i+1; $j <=$#$coord_systems; $j++){
            
            my $id_2 = $coord_systems->[$j][0];
            
            my $same_sql = "SELECT COUNT(*) FROM seq_region s1, seq_region s2
                                WHERE s1.coord_system_id = $id_1
                                AND s2.coord_system_id = $id_2
                                AND s1.name = s2.name";                   
                                
            my $count = DBUtils::RowCounter::get_row_count({
                helper => $helper,
                sql => $same_sql,
            });
        
            if($count > 0){
                $log->message("PROBLEM: Coordinate systems $id_1 and $id_2 have $count identically-named seq_regions"
                        . " - This may cause problems for ID mapping.");
                $names_result = 0;
            }
            else{
                $log->message("OK: Coordinate systems $id_1 and $id_2 have no identically-named seq_regions.");
            }
    
        }       
    }
    return $names_result;
}

=head2 check_length
    
  ARG[species_id]    : Int - species_id from meta table of the species being checked

  Returntype         : Boolean (0/1)

A SQL query returns the number of instances (=rows) where two sequences have the same name,
and are in different coordinate systems, but the sequence length isn't the same. Sequence length
should be the same, so if any rows are returned this points to a problem.

=cut

sub check_lengths{
    my ($species_id, $helper, $log) = @_;

    my $length_result = 1;

    my $length_sql = "SELECT COUNT(*) FROM seq_region s1, seq_region s2, coord_system c1, coord_system c2
                        WHERE s1.name = s2.name
                        AND s1.coord_system_id != s2.coord_system_id
                        AND c1.coord_system_id = s1.coord_system_id
                        AND c2.coord_system_id = s2.coord_system_id
                        AND s1.length != s2.length
                        AND c1.species_id = $species_id
                        AND c2.species_id = $species_id";

    #this needs revision
    if(index(lc($database_type), 'vega') != -1){
        $length_sql = $length_sql . " AND c1.version = c2.version";
    }

    my $count = DBUtils::RowCounter::get_row_count({
        helper => $helper,
        sql => $length_sql,
    });

    if($count > 0){
        $log->message("PROBLEM: $count regions have the same name but different lengths for species with id $species_id");
        $length_result = 0;
    }
    else{
        $log->message("OK: All seq_region lengths match for the species with id $species_id");
    }

    return $length_result;
}



