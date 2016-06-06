=head1 NAME

  DBUtils::CheckForOrphans

=head1 SYNOPSIS

  use DBUtils::CheckForOrphans;

  $test_result = DBUtils::CheckForOrphans::check_orphans(
      helper => $helper,
      table1 => 'exon',
      col1   => 'exon_id',
      table2 => 'exon_transcript',
      col2   => 'exon_id',
      both_ways => 0,
  );

=head1 DESCRIPTION

A module containing functionalities for foreigh key checking. When a foreign key references a
nonexistent tuple it is an orphan.

=cut

package DBUtils::CheckForOrphans;

use strict;
use warnings;

=head2 check_orphans

  ARG[helper]     : Bio::EnsEMBL::Utils::SqlHelper instance
  ARG[table1]     : String - name of the referencing table
  ARG[col1]       : String - name of the foreign key column in the referencing table
  ARG[table2]     : String (Optional) - name of the referenced table
  ARG[col2]       : String  (Optional)- name of the primary key colum in the referenced table
  ARG[both_ways]  : Boolean (Optional) - set to 1 (true) if you want to check the foreign key dependencies in both
                    directions.
  ARG[constraint] : String (Optional) - a constraint to be added to the query.

  Returntype      : Boolean (true if there are no orphans)

Tests if foreigh key col1 in table1 references an instance of col2 in table2. If both_ways is set to 1 it also checks
the reverse. If no value for col2 is given, it the value from col1 will be used for col2 as well. If both_ways is not given,
it will be set to 0.

=cut

sub check_orphans {
    my (%arg_for) = @_;

    my $helper = $arg_for{helper};
    my $log = $arg_for{logger};

    my $table1 = $arg_for{table1};
    my $col1   = $arg_for{col1};
    my $table2 = $arg_for{table2};
    my $col2   = $arg_for{col2};

    my $both_ways = $arg_for{both_ways};
    my $constraint = $arg_for{constraint};

    #value = is defined? // else this
    $col2 = $col2 // $col1;
    $both_ways = $both_ways // 0;
    $constraint = $constraint // '';

    my $sql_left = "SELECT COUNT(*) FROM $table1 LEFT JOIN $table2 "
                      . "ON $table1.$col1 = $table2.$col2 "
                      . "WHERE $table2.$col2 IS NULL";
                      
    if($constraint){
        $sql_left .= " AND $constraint";
    }

    my $result_left = $helper->execute_single_result(
        -SQL => $sql_left,
    );

    my $orphan_count;
    my $result_right;
    
    if($both_ways){
    
        my $sql_right = "SELECT COUNT(*) FROM $table2 LEFT JOIN $table1 "
                           . "ON $table2.$col2 = $table1.$col1 "
                           . "WHERE $table1.$col1 IS NULL";
                           
        if($constraint){
            $sql_right .= " AND $constraint";
        }

        $result_right = $helper->execute_single_result(
            -SQL => $sql_right,
        );

        $orphan_count = $result_left + $result_right;        

    }
    else{
         $orphan_count = $result_left;
    }
    

    if($orphan_count > 0){
        #in case you check both ways this will show you in which direction the orphans occur.
        if($result_left > 0){
        
            my $message = "PROBLEM: $result_left foreign key violations in "
                  . "$table1.$col1 -> $table2.$col2";
                  
            if($constraint){
                $message .= " with constraint: $constraint";
            }
            
            $log->message($message);
        }
        if($both_ways){
            if($result_right > 0){
            
                my $message = "PROBLEM: $result_right foreign key violations in "
                  . "$table2.$col2. -> $table1.$col1";
                  
                if($constraint){
                    $message .= " with constraint: $constraint";
                }
                
                $log->message($message);
            }
        }
        return 0;
    }
    else{
        my $message = "OK: No foreign key violations in $table1.$col1 -> $table2.$col2";
        if($constraint){
            $message .= " with constraint: $constraint";
        }
        if($both_ways){
            $message .= " or $table2.$col2 -> $table1.$col1";
            if($constraint){
                $message .= " with constraint: $constraint";
            }
        }
        
        $log->message($message);
        return 1;
    }
}


1;
