#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Getopt::Long;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use Logger;
use DBUtils::RowCounter;

my $registry = 'Bio::EnsEMBL::Registry';

my $parent_dir = File::Spec->updir;
my $file = $parent_dir . "/config";

my $species;
my $database_type;

my $config = do $file;
if(!$config){
    warn "couldn't parse $file: $@" if $@;
    warn "couldn't do $file: $!"    unless defined $config;
    warn "couldn't run $file"       unless $config; 
}
else {
    $registry->load_registry_from_db(
        -host => $config->{'db_registry'}{'host'},
        -user => $config->{'db_registry'}{'user'},
        -port => $config->{'db_registry'}{'port'},
    );
    #if there is command line input use that, else take the config file.
    GetOptions('species:s' => \$species, 'type:s' => \$database_type);
    if(!defined $species){
        $species = $config->{'species'};
    }
    if(!defined $database_type){
	$database_type = $config->{'database_type'};
    }
} 

my $log = Logger->new({
    healthcheck => 'SequenceLevel',
    type => $database_type,
    species => $species,
});

my $dba = $registry->get_DBAdaptor($species, $database_type);

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
);

my $result = 1;

$result &= check_version($helper, $log);

$result &= check_dna_attachment($helper, $log);

$log->result($result);


sub check_version{
    my ($helper, $log) = @_;
    
    my $sql = "SELECT count(*) FROM coord_system "
		. "WHERE name = 'contig' AND version is not NULL";

    my $rows = DBUtils::RowCounter::get_row_count({
	helper => $helper,
	sql => $sql,
    });
    
    if($rows > 0){
	$log->message("PROBLEM: Some contigs in the coord_system table have a version that is not NULL");
	return 0;
    }
    return 1;    
}

sub check_dna_attachment{
    my ($helper, $log) = @_;
    
    my $dna_result = 1;
    
    my $sql = "SELECT cs.name, COUNT(1) FROM coord_system cs, seq_region s, dna d "
		. "WHERE d.seq_region_id = s.seq_region_id "
		. "AND cs.coord_system_id = s.coord_system_id "
		. "AND cs.attrib NOT LIKE '%sequence_level%' "
		. "GROUP BY cs.coord_system_id";
		
    my $loose_systems = $helper->execute(
			-SQL => $sql,
		     );
    my @loose_systems = @{ $loose_systems };
    
    foreach my $loose_system (@loose_systems){
	$dna_result &= 0;
	my $coord_system = $loose_system->[0];
	my $rows = $loose_system->[1];
	
	$log->message("PROBLEM: Coordinate system $coord_system has $rows seq regions containing sequence, "
			. "but it does not have the sequence_level attribute");
    }
    
    return $dna_result;
}