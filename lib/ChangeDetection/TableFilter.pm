package ChangeDetection::TableFilter;

use Data::Dumper;
use File::Spec;
use Getopt::Long;

use strict;
use warnings;

my $parent_dir = File::Spec->updir;

sub filter_foreignkey_file{
    my ($changed_tables) = @_;

    use ChangeDetection::CoreForeignKeys;
    
    my @changed_tables = @{ $changed_tables };
    
    #build a hash?
    my %changed_keys;
    
    my %keys_hash = %$ChangeDetection::CoreForeignKeys::core_foreign_keys;
    
    foreach my $changed_table (@changed_tables){
        
        for my $table (keys %keys_hash){
            
           

            if($table eq $changed_table){
                ##everything goes
                my %table_hash;
                
                for my $test (keys %{ $keys_hash{$table} } ){
                    my %test_hash;
                    
                    $test_hash{col1} = $keys_hash{$table}{$test}{'col1'};
                    $test_hash{table2} = $keys_hash{$table}{$test}{'table2'};
                    $test_hash{col2} = $keys_hash{$table}{$test}{'col2'};
                    $test_hash{both_ways} = $keys_hash{$table}{$test}{'both_ways'};
                    $test_hash{constraint} = $keys_hash{$table}{$test}{'constraint'};
                
                    $table_hash{$test} = \%test_hash;
                }
                
                $changed_keys{$table} = \%table_hash;
            }
            else{
                my %table_hash;
                
                for my $test (keys %{ $keys_hash{$table} } ){
                    my %test_hash;
                    
                    my $table2 = $keys_hash{$table}{$test}{'table2'};
                    
                    if($table2 eq $changed_table){
                        ###this test goes
                        $test_hash{col1} = $keys_hash{$table}{$test}{'col1'};
                        $test_hash{table2} = $keys_hash{$table}{$test}{'table2'};
                        $test_hash{col2} = $keys_hash{$table}{$test}{'col2'};
                        $test_hash{both_ways} = $keys_hash{$table}{$test}{'both_ways'};
                        $test_hash{constraint} = $keys_hash{$table}{$test}{'constraint'};
                        
                        $table_hash{$test} = \%test_hash;
                    }  
                }
                if(scalar keys %table_hash){
                    $changed_keys{$table} = \%table_hash;
                }
            }
        }
    }
    
    my $file = "$parent_dir/lib/ChangeDetection/FilteredCoreForeignKeys.pm";
    open(my $fh, ">", $file)
        or die "cannot open > $file: $!";
        
    print $fh "package ChangeDetection::FilteredCoreForeignKeys; \n";
    print $fh "use strict; \n";
    print $fh "use warnings; \n";
    
    print $fh 'our $core_foreign_keys = ';
    
    $Data::Dumper::Terse = 1;
    print $fh Dumper( \%changed_keys) .";";
    
    close $fh or die "$file: $!";
    #print the hash to the file in such a way that CoreForeignKeys can read it.
}     

1;