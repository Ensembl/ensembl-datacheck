=head1 NAME

  CoreForeignKeys - Checks referential integrity of foreign keys in the databases (type 1 in the healthcheck system)

=head1 SYNPOPSIS

  $ perl CoreforeignKeys.pl --species 'homo sapiens'  --type 'core'

=head1 DESCRIPTION

  --species 'species name'      : String (Optional) - name of the species to check on.
  --type 'database type'        : String (Optional) - name of the database type to test on. 
  --filter_tables               : Flag - use it if you're runnigng the HealthCheckSuite and have filtered the input file for
                                  CoreForeigKeys - it will use Input::FilteredCoreForeignKeys.
  --config_file                 : String (Optional) - location of the config file relative to the working directory. Default
                                  is one folder above the working directory.
                                  
If no command line input arguments are given, values from the 'config' file in the parent directory of the working directory will be used.  
If the filter_tables flag is not set, foreign key pairs will be taken from the Input::CoreForeignKeys module. 
  
Tests all foreign key references in the generic databases with the use of the CheckForOrphans module. 

Perl adaptation of the CoreForeignKeys.java and AncestralSequencesExtraChecks.java healthchecks
See: https://github.com/Ensembl/ensj-healthcheck/blob/release/84/src/org/ensembl/healthcheck/testcase/generic/CoreForeignKeys.java
and: https://github.com/Ensembl/ensj-healthcheck/blob/release/84/src/org/ensembl/healthcheck/testcase/generic/AncestralSequencesExtraChecks.java

=cut

#!/usr/bin/env perl

use warnings;
use strict;

use File::Spec;
use Getopt::Long qw(:config pass_through);

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use Logger;


use DBUtils::Connect;
use DBUtils::CheckForOrphans;
use DBUtils::TableSets;
use DBUtils::RowCounter;

use ChangeDetection::TableFilter;

my $filter_tables;
my $config_file;

GetOptions("filter_tables" => \$filter_tables, 'config_file:s' => \$config_file);

my $dba = DBUtils::Connect::get_db_adaptor($config_file);

my $species = DBUtils::Connect::get_db_species($dba);
my $database_type = $dba->group();

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
    );

my $log = Logger->new({
    healthcheck => 'CoreForeignKeys',
    type => $database_type,
    species => $species,
});
    
my $test_result = 1;



my %tables_hash;

if($filter_tables){
    use Input::FilteredCoreForeignKeys;
    %tables_hash = %$Input::FilteredCoreForeignKeys::core_foreign_keys;
}
else{
    use Input::CoreForeignKeys;
    %tables_hash = %$Input::CoreForeignKeys::core_foreign_keys;
}

for my $table (keys %tables_hash ) {

    for my $test (keys %{ $tables_hash{$table} } ){

        my $test_def = $tables_hash{$table}{$test};
    
        $test_result &= DBUtils::CheckForOrphans::check_orphans(
            helper => $helper,
            logger => $log,
            table1 => $table,
            %{$test_def}
        );
    }
}


if($database_type eq 'sangervega'){
    $test_result &= DBUtils::CheckForOrphans::check_orphans_with_constraint(
                        helper => $helper,
                        logger => $log,
                        table1 => 'misc_feature',
                        col1 => 'misc_feature_id',
                        table2 => 'misc_attrib',
                        col2 => 'misc_feature_id',
                        constraint => "misc_feature.misc_feature_id NOT IN " .
                                          "(SELECT mfms.misc_feature_id FROM misc_feature_misc_set AS mfms "
                                            . "JOIN misc_set AS ms ON mfms.misc_set_id = ms.misc_set_id "
                                            .  "AND ms.code = 'noAnnotation')",
                     );
}
else {
    $test_result &= DBUtils::CheckForOrphans::check_orphans(
        helper => $helper,
        logger => $log,
        table1 => 'misc_feature',
        col1 => 'misc_feature_id',
        table2 => 'misc_attrib',
        col2 => 'misc_feature_id',
        both_ways => 0,
    );
}


my @types = ("Gene", "Transcript", "Translation");
foreach my $type (@types){
    $test_result &= check_keys_by_ensembl_object_type(
	    helper => $helper,
	    logger => $log,
	    object => 'object_xref',
	    type => $type,
	);
}



my @analysis_tables = @{ DBUtils::TableSets::get_tables_with_analysis_id() };

foreach my $analysis_table (@analysis_tables){

	if($analysis_table eq 'protein_align_feature' || $analysis_table eq 'dna_align_feature'
	   || $analysis_table eq 'repeat_feature'){
        next;	   
	}
	
	my $constraint = "$analysis_table.analysis_id IS NOT NULL";
	if($analysis_table eq 'object_xref'){
		$constraint .= " and $analysis_table.analysis_id != 0";
	}
	
	$test_result &= DBUtils::CheckForOrphans::check_orphans(
	    helper => $helper,
	    logger => $log,
	    table1 => $analysis_table,
	    col1 => 'analysis_id',
	    table2 => 'analysis',
	    col2 => 'analysis_id',
	    constraint => $constraint,
	);

}


$test_result &= check_display_marker_synonym_id($helper, $log);

$log->result($test_result);

sub check_keys_by_ensembl_object_type{
	my (%arg_for) = @_;
	
	my $helper = $arg_for{helper};
	my $log = $arg_for{logger};
	my $object = $arg_for{object};
	my $type = $arg_for{type};
	
	my $table = $type;
	#find camelcase capital letters and separate them by _ instead and convert to lower case.
	$table =~ s/([a-z])([A-Z])/$1_$2/;
	$table = lc($table);
	
	my $column;
	if($object eq 'object_xref'){
		$column = 'ensembl_id';
	}
	else{
		$column = 'ensembl_object_id';
	}
	
	my $result = DBUtils::CheckForOrphans::check_orphans(
	    helper => $helper,
	    logger => $log,
	    table1 => $object,
	    col1 => $column,
	    table2 => $table,
	    col2 => $table . "_id",
	    constraint => "$object.ensembl_object_type = \'$type\'",
	);
	
	return $result;
}

sub check_display_marker_synonym_id{
	my ($helper, $log) = @_;
	
	my $result = 1;
	
	my $sql = "SELECT COUNT(*) FROM marker m " 
	           . "WHERE m.display_marker_synonym_id NOT IN "
			       . "(SELECT ms.marker_synonym_id FROM marker_synonym ms "
				         . "WHERE m.marker_id = ms.marker_id)";
	
	my $number_of_rows = DBUtils::RowCounter::get_row_count({
	    helper => $helper,
	    sql => $sql,
	});
	
	if ($number_of_rows > 0){
		$result = 0;
		$log->message("PROBLEM: There are markers that have a display_marker_id "
				. "that is not part of the synonyms for marker");
	}
	
	return $result;
}
