=head1 NAME

  Meta - A sanity test on database information in the meta table (type 3 in the healthcheck system).

=head1 SYNOPSIS

  $perl Meta.pl --species 'homo sapiens' --type 'core'
  
=head1 DESCRIPTION

  --species 'species name'     : String (Optional) - name of the species to test.
  --type 'database type'       : String (Optional) - type of the database to test on
  --config_file                : String (Optional) - location of the config file relative to the working directory. Default
                                 is one folder above the working directory.
  
  Database type                : All generic databases (core, vega, cdna, otherfeatures, rnaseq)
  
 If no command line input arguments are given, values from the 'config' file in the parent directory of the working directory will be used.
  
 The meta healthcheck checks if the meta table exists in the database, if it has rows, if
 the schema version in the meta table matches that of the database name, if there are certain
 keys for key/value pairs used, if there are no duplicate key/value pairs, and if there
 are no values that have 'ARRAY(...' instead of an actual value.
  
 Perl implementation of the Meta.java test
 See: https://github.com/Ensembl/ensj-healthcheck/blob/release/84/src/org/ensembl/healthcheck/testcase/generic/Meta.java
  
=cut
#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Getopt::Long qw(:config pass_through);

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use Logger;
use DBUtils::Connect;
use DBUtils::TableExistence;
use DBUtils::RowCounter;
use DBUtils::FromDBName;

my $config_file;

GetOptions('config_file:s' => \$config_file);

my $dba = DBUtils::Connect::get_db_adaptor($config_file);

my $species = DBUtils::Connect::get_db_species($dba);
my $database_type = $dba->group();

my $log = Logger->new({
    healthcheck => 'Meta',
    type => $database_type,
    species => $species,
});

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
);

my $result = 1;

$result &= check_table_exists($helper, $log);
$result &= check_has_rows($helper, $log);

$result &= check_version($helper, $log, $dba);

my $dbname = ($dba->dbc())->dbname();

if(index($dbname, 'ancestral') == -1){
    if(lc($database_type) eq 'core'){
	$result &= check_keys_present($helper, $log);
    }
    
    $result &= check_duplicates($helper, $log);
    $result &= check_for_arrays($helper, $log);
}

$log->result($result);

=head2 check_table_exists

  ARG[helper]     : Bio::EnsEMBL::Utils::SqlHelper instance
  ARG[Logger]     : Logger object instance
  
  Returntype      : Boolean
  
Checks if the meta table exists.

=cut

sub check_table_exists{
    my ($helper, $log) = @_;
    
    if(DBUtils::TableExistence::does_table_exist($helper, 'meta')){
	$log->message("OK: Meta table present");
	return 1;
    }
    else{
	$log->message("PROBLEM: Meta table not present");
	return 0;
    }
}

=head2 check_has_rows

  ARG[helper]     : Bio::EnsEMBL::Utils::SqlHelper instance
  ARG[Logger]     : Logger object instance
  
  Returntype      : Boolean
  
Checks if the meta table has rows.

=cut

sub check_has_rows{
    my ($helper, $log) = @_;
    
    my $rows = DBUtils::RowCounter::get_row_count({
		    helper => $helper,
		    sql => "SELECT * FROM meta",
		    });
		    
    if($rows){
	$log->message("OK: Meta table has rows");
	return 1;
    }
    else{
	$log->message("PROBLEM: Meta table has no rows");
	return 0;
    }    
}

=head2 check_version

  ARG[helper]     : Bio::EnsEMBL::Utils::SqlHelper instance
  ARG[Logger]     : Logger object instance
  ARG[dba]        : Bio::EnsEMBL::DBSQL::DBAdaptor instance
  
  Returntype      : Boolean

  Checks if the version number in the meta table is in numeric format, and
  if it matches the version number in the database name.
=cut

sub check_version{
    my($helper, $log, $dba) = @_;
    
    my $schema_result = 1;
    my $version_no = DBUtils::FromDBName::get_version($dba);
    
    if($version_no eq 'UNKNOWN'){
	$log->message("PROBLEM: Could not extract version number from database name");
	$schema_result = 0;
    }
    
    my $sql_result = $helper->execute(
	-SQL => "SELECT meta_value FROM meta WHERE meta_key = 'schema_version'",
    );
    
    my $schema_version = $sql_result->[0][0];
    
    if(!defined $schema_version){
	$log->message("PROBLEM: schema_version not defined in meta table");
	$schema_result = 0;
    }
    else{
        if($schema_version !~ /[0-9]+/){
            $log->message("PROBLEM: schema_version from meta table not in numeric format");
            $schema_result = 0;
        }
        else{
            if($version_no == $schema_version){
                $log->message("OK: Versions from meta table and database name match");
            }
            else{
                $log->message("PROBLEM: Versions from meta table and database do not match");
                $schema_result = 0;
            }
        }
    }
    
    return $schema_result;
}

=head2 check_keys_present

  ARG[helper]     : Bio::EnsEMBL::Utils::SqlHelper instance
  ARG[Logger]     : Logger object instance
  
  Returntype      : Boolean
  
Checks that a number of values for meta_key exist in the meta table. Also checks that
there are at least three different species.alias keys.
  
=cut

sub check_keys_present{
    my ($helper, $log) = @_;
    
    my $key_result = 1;
    
    my @meta_keys = ("assembly.default", "assembly.name", "assembly.date", "assembly.coverage_depth",
		     "species.classification", "species.common_name", "species.display_name",
		     "species.production_name", "species.scientific_name", "species.stable_id_prefix",
		     "species.taxonomy_id", "species.url", "repeat.analysis");
		     
    foreach my $meta_key (@meta_keys){
	my $rows = DBUtils::RowCounter::get_row_count({
	    helper => $helper,
	    sql => "SELECT COUNT(*) FROM meta WHERE meta_key = '$meta_key'",
	});
	if($rows == 0){
	    $log->message("PROBLEM: No entry in meta table for $meta_key");
	    $key_result = 0;
	}
    }
    
    #in case of species aliases there should be at least 3
    my $aliases = DBUtils::RowCounter::get_row_count({
	helper => $helper,
	sql => "SELECT COUNT(*) FROM meta WHERE meta_key = 'species.alias'",
    });
    
    if($aliases < 3){
	$log->message("PROBLEM: There should be min. 3 entries for species.alias in meta. There are only $aliases entries");
	$key_result = 0;
    }
    
    return $key_result;
}

=head2 check_duplicates

  ARG[helper]     : Bio::EnsEMBL::Utils::SqlHelper instance
  ARG[Logger]     : Logger object instance
  
  Returntype      : Boolean

Checks that there are no duplicate meta_key meta_value pairs.

=cut

sub check_duplicates{
    my($helper, $log) = @_;
    
    my $duplicate_result = 1;
    
    my $duplicates = $helper->execute(
	-SQL => "SELECT meta_key, meta_value FROM meta GROUP BY meta_key, meta_value, species_id HAVING COUNT(*) > 1",
    );
    
    my @duplicates = @{ $duplicates };
    
    foreach my $duplicate (@duplicates){
	my $key = $duplicate->[0];
	my $value = $duplicate->[1];
	
	$log->message("PROBLEM: Key/value pair $key/$value appears more than once in the meta table");
	$duplicate_result = 0;
    }
    
    return $duplicate_result;
 }
 
=head2 check_duplicates

  ARG[helper]     : Bio::EnsEMBL::Utils::SqlHelper instance
  ARG[Logger]     : Logger object instance
  
  Returntype      : Boolean

Checks that there are no meta_value entries that have a value like 'ARRAY(...'.
  
=cut
 
 sub check_for_arrays{
    my($helper, $log) = @_;
    
    my $array_result = 1;
    
    my $sql_result = $helper->execute(
	-SQL => "SELECT meta_key, meta_value FROM meta WHERE meta_value LIKE 'ARRAY(%'",
    );
    
    my @array_values = @{ $sql_result };
    
    foreach my $array_value (@array_values){
	my $key = $array_value->[0];
	my $value = $array_value->[1];
	
	$log->message("PROBLEM: Meta table entry for $key has value $value which is probably incorrect");
	my $array_result = 0;
    }
    
    return $array_result;
}
	
	