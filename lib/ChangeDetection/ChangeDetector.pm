package ChangeDetection::ChangeDetector;

use strict;
use warnings;

use Data::Dumper;

use DBUtils::Connect;

use Bio::EnsEMBL::Utils::SqlHelper;
use Bio::EnsEMBL::DBSQL::DBAdaptor;


sub get_changed_tables{
    my ($dba) = @_;

    my $dbname = ($dba->dbc())->dbname();

    my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
        -DB_CONNECTION => $dba->dbc()
        );     

    my $updates = get_table_updates($helper);

    my $changed_tables = compare_updates($dbname, $updates);

    return $changed_tables;
}

sub get_table_updates{
    my ($helper) = @_;
    
    my $sql = "SELECT TABLE_NAME, UPDATE_TIME FROM information_schema.tables "
                . "WHERE table_schema = DATABASE()";
                
    my $table_updates = $helper->execute_into_hash(
        -SQL => $sql,
    );
    
    return $table_updates;
}

sub tables_to_file{
    my ($dbname, $hash_ref) = @_;
    
    my $file = $dbname;
    
    open(my $fh, ">", $file)
        or die "cannot open > $file: $!";

    $Data::Dumper::Terse = 1;
    print $fh Dumper($hash_ref);
    
    close $fh or die "$file: $!";
}

sub compare_updates{
    my ($dbname, $hash_ref) = @_;
    
    my %new_tables = %$hash_ref;
    
    my @changed_tables;
    
    my $file = $dbname;
    
    if(-f $file){
        my $old_tables = do $file;
        if(!$old_tables){
            warn "couldn't parse $file: $@" if $@;
            warn "couldn't do $file: $!"    unless defined $old_tables;
            warn "couldn't run $file"       unless $old_tables;
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
            tables_to_file($dbname, $hash_ref);
        }
    }
    else{
        #if the file doesn't exist we create it
        tables_to_file($dbname, $hash_ref);
        #all tables are assumed to have changed.
        for my $table_name (keys %new_tables){
            push @changed_tables, $table_name;
        }
    }
    
    
    return \@changed_tables;
}    
    
1    
