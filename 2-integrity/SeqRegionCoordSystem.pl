=head1 NAME

  SeqRegionCoordsystem - A user-defined integrity test (type 2 in the healthcheck system)

=head1 SYNOPSYS

  $ perl SeqRegionCoordSystem.pl 'homo sapiens' 'core'

=head1 DESCRIPTION

  ARG[Species Name]       : String - Name of the species to test on*.
  ARG[Database type]      : String - Database type to test on.

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

#!/usr/bin/evn perl

use strict;
use warnings;

use File::Spec;
use Getopt::Long;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use DBUtils::RowCounter;
use DBUtils::MultiSpecies;

my $registry = 'Bio::EnsEMBL::Registry';

my ($species, $database_type);

my $parent_dir = File::Spec->updir;
my $file = $parent_dir . "/config";

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
    GetOptions('species:s' => \$species, 'type:s' => \$database_type);
    if(!defined $species){
        $species = $config->{'species'};
    }
    if(!defined $database_type){
        $database_type = $config->{'database_type'};
    }
    print "$species $database_type \n";
} 

my $dba = $registry->get_DBAdaptor($species, $database_type);

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
);

my $result = 1;

if(DBUtils::MultiSpecies::is_multi_species($dba)){
    #if it is a multispecies database, get all the distinct species_ids...
    my $species_ids = DBUtils::MultiSpecies::get_multi_species_ids($helper);
    
    #...and iterate over them to run the test on each species.
    foreach my $species_id (@$species_ids){
        foreach my $id (@$species_id){

            print "Checking species by ID $id: \n";
            if(lc($database_type) eq 'core'){
                $result &= check_names($id);
            }
            $result &= check_lengths($id);
            print "\n";
        }
    }
}
else{
    #IS THIS ASSUMPTION VALID? if there is only one species in the database it's species_id is 1.
    if(lc($database_type) eq 'core'){
        $result &= check_names(1);
    }
    $result &= check_lengths(1);
}

print $result . "\n";

=head2 check_names
    
  ARG[species_id]    : Int - species_id from meta table of the species being checked

  Returntype         : Boolean (0/1)

A SQL query returns the number of instances (=rows) where two sequences have the same
name but different coordinate systems for the same species_id. This should not happen
in core databases, so if any rows are returned it points to a mistake.

=cut

sub check_names{
    my ($species_id) = @_;

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
                print "PROBLEM: Coordinate systems $id_1 and $id_2 have $count identically-named seq_regions"
                        . " - This may cause problems for ID mapping. \n";
                $names_result = 0;
            }
            else{
                #print "OK: Coordinate systems $id_1 and $id_2 have no identically-named seq_regions. \n";
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
    my ($species_id) = @_;

    my $length_result = 1;

    my $length_sql = "SELECT COUNT(*) FROM seq_region s1, seq_region s2, coord_system c1, coord_system c2
                        WHERE s1.name = s2.name
                        AND s1.coord_system_id != s2.coord_system_id
                        AND c1.coord_system_id = s1.coord_system_id
                        AND c2.coord_system_id = s2.coord_system_id
                        AND s1.length != s2.length
                        AND c1.species_id = $species_id
                        AND c2.species_id = $species_id";

    if(index(lc($database_type), 'vega') != -1){
        $length_sql = $length_sql . " AND c1.version = c2.version";
    }

    my $count = DBUtils::RowCounter::get_row_count({
        helper => $helper,
        sql => $length_sql,
    });

    if($count > 0){
        print "PROBLEM: $count regions have the same name but different lengths for species with id $species_id \n";
        $length_result = 0;
    }
    else{
        #print "OK: All seq_region lengths match for the species with id $species_id \n";
    }

    return $length_result;
}



