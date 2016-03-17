
package DBUtils::SqlComparer;

use Bio::EnsEMBL::Utils::SqlHelper;

sub check_same_sql_result{
    my (%arg_for) = @_;
    
    my $sql = $arg_for{sql};
    my $species = $arg_for{species};
    my $types_ref = $arg_for{types};
    my $meta = $arg_for{meta};
    
    my @types = @{ $types_ref };

    my $final_result = 1;

    my @sql_results;

    foreach $type (@types){

        my $dba = Bio::EnsEMBL::Registry->get_DBAdaptor($species, $type);

        my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
        -DB_CONNECTION => $dba->dbc()
        );

        my $sql_result = $helper->execute(
            -SQL => $sql,
        );

        push @sql_results, $sql_result;
    }

    for(my $i = 0; $i <= $#sql_results; $i++){
        for(my $j = $i+1; $j <= $#sql_results; $j++){
            
            if($meta){
                #do the meta stuff
            }
            
            $final_result &= compare_sql_results(
                result1 => @sql_results[$i],
                result2 => @sql_results[$j],
            );
        }
    }
        

    return $final_result;

}

sub compare_sql_results{
    my (%arg_for) = @_;
    
    my $result1 = $arg_for{result1};
    my $result2 = $arg_for{result2};

    if($#$result1 != $#$result2){
        print "Number of rows does not match \n";
        return 0;
    }

    for(my $i = 0; $i <= $#$result1; $i++){

        my $column_no1 = $result1->[$i];
        my $column_no2 = $result2->[$i];

        if($#$column_no1 != $#$column_no2){
            print "Number of columns does not match \n";
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
                print "Values don't match \n";
                return 0;
            }

            
        }        
    }
    print "Tables match! \n";
    return 1;
}


1;
