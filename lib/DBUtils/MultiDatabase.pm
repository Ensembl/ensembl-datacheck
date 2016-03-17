package DBUtils::MultiDatabase;

use strict;
use warnings;

use DBUtils::SqlComparer;

sub check_sql_across_species{
    my (%arg_for) = @_;

    my $sql = $arg_for{sql};
    my $registry = $arg_for{registry};
    my $types = $arg_for{types};

    my @database_types = @{ $types };
    
    my @species_names = @{ $registry->get_all_species() };

    my $final_result = 1;

    #this shoud be argument as well
    #@database_types = ('core', 'cdna', 'otherfeatures', 'rnaseq');

    foreach my $species_name (@species_names){
        my @species_dbas = @{ $registry->get_all_DBAdaptors(
            -species => $species_name    
             ) };

        my @filtered_types;

        foreach my $species_dba (@species_dbas){
            my $group = $species_dba->group();
            if(grep {$_ eq $group} @database_types){
                push @filtered_types, $group;
            }
        }
        
        my $filtered_types_ref = \@filtered_types;
        print "$species_name: \n";
        $final_result &= DBUtils::SqlComparer::check_same_sql_result(
                                sql => $sql,
                                species => $species_name,
                                types => $filtered_types_ref,
                                meta => 0,
                            );
        print "\n";
    }
    return $final_result;
}


1;
