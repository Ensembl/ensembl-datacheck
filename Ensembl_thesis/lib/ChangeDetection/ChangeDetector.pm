=head1 NAME

  ChangeDetection::ChangeDetector
  
=head1 SYNOPSIS

  use ChangeDetection::ChangeDetector;
  my $changed_tables = ChangeDetection::ChangeDetector::get_changed_tables($dba);

=head1 DESCRIPTION

  Retrieves table_name (s) and update_time (s) from information_schema.tables from the database
  through the database adaptor provided. Looks for a file with the same name as the database. If found,
  it compares the update_time value for each table_name and returns the tables that have changed. If the
  file is not found, all tables are returned as they are all assumed to have changed.
    
=cut

package ChangeDetection::ChangeDetector;

use strict;
use warnings;

use Data::Dumper;

use DBUtils::Connect;

use Bio::EnsEMBL::Utils::SqlHelper;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Utils::Exception qw( throw warning); 

=head2 get_changed_tables

  ARG($dba)     : Bio::EnsEMBL::DBSQL::DBAdaptor object
  Returntype    : Arrayref containing all the changed tables
  
  Retrieves the tables that have changed in the database of the DBAdaptor since the last time this function
  was called.
  
=cut

sub get_changed_tables{
    my ($dba) = @_;

    my $dbname = ($dba->dbc())->dbname();

    my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
        -DB_CONNECTION => $dba->dbc()
        );     

    my $updates = get_table_updates($helper);

    my $changed_tables = _compare_updates($dbname, $updates);

    return $changed_tables;
}

=head2 get_table_updates

  ARG($helper)  : Bio::EnsEMBL::Utils::SqlHelper object
  Returntype    : Hashref containing the table names as keys and update time as values.
  
  Queries the database for the update times of all tables.
  
=cut

sub get_table_updates{
    my ($helper) = @_;
    
    my $sql = "SELECT TABLE_NAME, UPDATE_TIME FROM information_schema.tables "
                . "WHERE table_schema = DATABASE()";
                
    my $table_updates = $helper->execute_into_hash(
        -SQL => $sql,
    );
    
    return $table_updates;
}

=head2 _tables_to_file

  ARG($dbname)     : String - name of the database
  ARG($hash_ref)   : Hashref - containting the values you want to print
  
  Prints the hash_ref to a file with the same name as the database.
  
=cut

sub _tables_to_file{
    my ($dbname, $hash_ref) = @_;
    
    my $file = $dbname;
    
    open(my $fh, ">", $file)
        or throw("cannot open > $file: $!");

    $Data::Dumper::Terse = 1;
    print $fh Dumper($hash_ref);
    
    close $fh or warning("$file: $!");
}

=head2 _compare_updates

  ARG($db_name)    : String - name of the database
  ARG($hash_ref)   : Hashref containing the latest table_name update_time pairs.
  Returntype       : Arrayref containing all the changed tables.
  
  Looks for a file with the same name as the database. If found, it compares the update_time of the file
  to that in the hash for each table_name. If the table has changed, the table_name is pushed into an array.
  Once all tables have been checked the hash_ref is printed to the file to keep it up to date.
  If the file is not found, all tables are assumed to have changed. All table_name (s) are pushed into an
  array, and the hash_ref is printed to a new file. 
  The array_ref of the array containing all the changed tables is then returned.

=cut

sub _compare_updates{
    my ($dbname, $hash_ref) = @_;
    
    my %new_tables = %$hash_ref;
    
    my @changed_tables;
    
    my $file = $dbname;
    
    if(-f $file){
        my $old_tables = do $file;
        if(!$old_tables){
            throw("couldn't parse $file: $@") if $@;
            throw("couldn't do $file: $!")    unless defined $old_tables;
            throw("couldn't run $file")       unless $old_tables;
        }
        else{          
            my $new_time;
            my $old_time;
            
            #loop over new table info
            #for each table name fetch the oldtime from the file and compare.
            #if new time is earlier put the table into the array with changed tables
            for my $table_name (keys %new_tables){
                my $new_time = $new_tables{$table_name};
                my $old_time = $old_tables->{$table_name};
                
                if($new_time gt $old_time){
                    push @changed_tables, $table_name;
                }
                #print "$table_name $new_time $old_time \n";
            }
            #rewrite the file with the new information
            _tables_to_file($dbname, $hash_ref);
        }
    }
    else{
        #if the file doesn't exist we create it
        _tables_to_file($dbname, $hash_ref);
        #all tables are assumed to have changed.
        for my $table_name (keys %new_tables){
            push @changed_tables, $table_name;
        }
    }
    
    
    return \@changed_tables;
}    
    
1    
