
=head1 NAME

  DBUtils::SqlComparer

=head1 SYNOPSIS

  use DBUtils::SqlComparer

  my $same_boolean = DBUtils::SqlComparer::check_same_sql_result{
    sql => $sql,
    species => $species,
    types => $datbase_types
    meta => $meta_boolean
  }

  my $comparison_boolean = DBUtils::SqlComparer::compare_sql_boolean{
    result1 => $sql_query_result1,
    result2 => $sql_query_result2,
  }

  my $same_multiple_species = DBUtils::SqlComparer::check_sql_across_species{
    sql => $sql,
    registry => $registry,
    types => $database_types
    meta => $meta_boolean
  }

=head1 DESCRIPTION

A module with functions to compare the results of a query on different databases. The compare_sql_boolean 
sub compares two results (in the form of arrayrefs) on row count, column count, and content.
The check_same_sql_result takes an array ref of database types and compares query results between each of
them using the compare_sql_boolean. If $meta is set to true it also queries meta data on column names and
types and compares this as well.
The check_sql_across_species sub retrieves all the species from the provided registry and calls the 
check_same_sql_result on each of them.
=cut

package DBUtils::SqlComparer;

use Bio::EnsEMBL::Utils::SqlHelper;
use Bio::EnsEMBL::Utils::Exception qw(throw warning);

=head2 check_same_sql_result

  ARG[sql]        : String - the sql query of which the results will be compared.
  ARG[species]    : String - the species for which you want to compare results.
  ARG[types]      : Arrayref - an arrayref for all the database types which you want to query.
  ARG[meta]       : Boolean - if true will compare metadata on the FIRST table from your sql query.
  
  Returntype      : Boolean - true if results are the same.

Performs the sql query on all the given datbase types of the species. Then calls compare_sql_boolean to
compare the results.

=cut

sub check_same_sql_result{
    my (%arg_for) = @_;
    
    my $sql = $arg_for{sql};
    my $species = $arg_for{species};
    my $types_ref = $arg_for{types};
    my $meta = $arg_for{meta};
    my $log = $arg_for{logger};
    
    my @types = @{ $types_ref };
    
    $log->species($species);

    my $final_result = 1;

    my @sql_results;

    my @meta_results;

    foreach $type (@types){
	#set logger for the database type
	$log->type($type);

        my $dba = Bio::EnsEMBL::Registry->get_DBAdaptor($species, $type);
        if(!defined $dba){
            warning("No DBA adaptor found for this database type/species combination: $species, $type");
            next;
        }
            
        my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
        -DB_CONNECTION => $dba->dbc()
        );

        my $sql_result = $helper->execute(
            -SQL => $sql,
        );

        push @sql_results, $sql_result;

        if($meta){

            my $dbname = ($dba->dbc())->dbname();

            if(lc($sql) =~ /from (\S+)/ ){
                my $tablename = $1;
                my $meta_sql = "SHOW COLUMNS FROM $tablename IN $dbname";

                my $meta_result = $helper->execute(
                    -SQL => $meta_sql
                );

                push @meta_results, $meta_result;
            }
            else{
                $log->message("PROBLEM: Unable to do meta table comparison: can't extract table name");
            }
        }

    }
    
    #logger is general case for database types again
    $log->type('undefined');

    for(my $i = 0; $i <= $#sql_results; $i++){
        for(my $j = $i+1; $j <= $#sql_results; $j++){
            
            $final_result &= compare_sql_results(
                result1 => @sql_results[$i],
                result2 => @sql_results[$j],
                logger => $log,
            );
        }
    }

    if($meta){
        for(my $i = 0; $i <= $#$meta_results; $i++){
            for(my $j = $j+1; $j <= $#$meta_results; $j++){

                $final_result &= compare_sql_results(
                    result1 => @meta_results[$i],
                    result2 => @meta_results[$j],
                    logger => $log,
                );
            }
        }
    }        

    if($final_result){
        $log->message("OK: Tables for $species match");
    }
    return $final_result;

}

=head2 compare_sql_result

  ARG[result1]     : Arrayref - Reference to the array containing the results of the query on the first database
  ARG[result2]     : Arrayref - Reference to the array containing the results of the query on the second database
  
  Returntype       : Boolean - true if results are the same.

Iterates over both of the arrayrefs to compare the number of rows, the number of columns, and the content in
each cell.
NOTE: Right now it prints when the results do not match but it doesn't give any information on where the
mistake happens. This should be improved.
=cut

sub compare_sql_results{
    my (%arg_for) = @_;
    
    my $result1 = $arg_for{result1};
    my $result2 = $arg_for{result2};
    my $log = $arg_for{logger};

    if($#$result1 != $#$result2){
        $log->message("PROBLEM: Number of rows does not match");
        return 0;
    }

    for(my $i = 0; $i <= $#$result1; $i++){

        my $column_no1 = $result1->[$i];
        my $column_no2 = $result2->[$i];

        if($#$column_no1 != $#$column_no2){
            $log->message("PROBLEM: Number of columns does not match");
            return 0;
        }

        for(my $j = 0; $j <= $#$column_no1; $j++){
            
            my $value1;
            if(defined $result1->[$i][$j]){            
                $value1 = $result1->[$i][$j];
            }
            else{
                $value1 = 'NULL';
            }
            
            my $value2;
            if(defined $result2->[$i][$j]){
                $value2 = $result2->[$i][$j];
            }
            else{
                $value2 = 'NULL';
            }

            if(!($value1 eq $value2)){
                $log->message("PROBLEM: Values don't match: $value1 and $value2");
                return 0;
            }

            
        }        
    }
 
    return 1;
}

=head2 check_sql_across_species

  ARG[sql]        : String - the sql query of which the results will be compared.
  ARG[registry]   : Database registry instance.
  ARG[types]      : Arrayref - an arrayref for all the database types which you want to query.
  ARG[meta]       : Boolean - if 1 will compare metadata on the FIRST table from your sql query.
  
  Returntype      : Boolean - true if the sql gives the same result across all the database types for each species.

Retrieves all the species from the given registry. Iterates over each species, calling the 
check_same_sql_result sub on them to compare the given database types on the results of the provided sql.

=cut

sub check_sql_across_species{
    my (%arg_for) = @_;

    my $sql = $arg_for{sql};
    my $registry = $arg_for{registry};
    my $types = $arg_for{types};
    my $meta = $arg_for{meta};
    my $log = $arg_for{logger};

    my @database_types = @{ $types };
    
    my @species_names = @{ $registry->get_all_species() };

    my $final_result = 1;

    foreach my $species_name (@species_names){
	#set the logger for the species
	$log->species($species_name);
    
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
        #print "Checking tables for $species_name: \n";
        $final_result &= check_same_sql_result(
                                sql => $sql,
                                species => $species_name,
                                types => $filtered_types_ref,
                                meta => $meta,
                                logger => $log,
                            );
    }
    return $final_result;
}

1;
