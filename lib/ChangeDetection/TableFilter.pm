=head1 NAME
  
  ChangeDetection::TableFilter
  
=head1 SYNOPSIS

  use ChangeDetection::TableFilter;
  ChangeDetection::TableFilter::filter_foreignkey_file($changed_tables_ref);
  
  $CoreForeignKeyObject->run_healthcheck(
    -path => '.',
    -command => '--config_file 'config' --filter_tables',
  );

=head1 DESCRIPTION

  Module for filtering the input files of healthchecks that use a lot of tables. Currently only for CoreForeignKeys.

=cut

package ChangeDetection::TableFilter;

use strict;
use warnings;

use Data::Dumper;
use File::Spec;
use Getopt::Long;

use Bio::EnsEMBL::Utils::Exception qw( throw warning );

my $parent_dir = File::Spec->updir;

=head2 filter_foreignkey_file

  ARG($changed_tables)  : Arrayref - all the tables that have changed (and thus will need to be tested)
  
  Filters out all the CheckForOrphan inputs to only contain those that involve the changed tables, and
  prints these to a new file (FilteredCoreForeignKeys), which is used by the CoreForeignKey if you use
  the --filter_tables flag when calling it. Atm this module assumes you're calling it from the main directory 
  of the healthchecks.

=cut

sub filter_foreignkey_file{
    my ($changed_tables) = @_;

    use Input::CoreForeignKeys;
    
    my @changed_tables = @{ $changed_tables };
    
    #build a hash?
    my %changed_keys;
    
    my %keys_hash = %$Input::CoreForeignKeys::core_foreign_keys;
    
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
    
    my $file = File::Spec->catfile(('lib', 'Input'), 'FilteredCoreForeignKeys.pm');
    open(my $fh, ">", $file)
        or warning("cannot open > $file: $!");
        
    print $fh "package Input::FilteredCoreForeignKeys; \n";
    print $fh "use strict; \n";
    print $fh "use warnings; \n";
    
    print $fh 'our $core_foreign_keys = ';
    
    $Data::Dumper::Terse = 1;
    print $fh Dumper( \%changed_keys) .";";
    
    close $fh or warning("$file: $!");
    #print the hash to the file in such a way that CoreForeignKeys can read it.
}     

1;