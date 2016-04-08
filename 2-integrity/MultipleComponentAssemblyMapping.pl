#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Getopt::Long;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use Logger;

#UNFINISHED

my $registry = 'Bio::EnsEMBL::Registry';

my $parent_dir = File::Spec->updir;
my $file = $parent_dir . "/config";

my $species;
my $database_type = "core";

my $config = do $file;
if(!$config){
    warn "couldn't parse $file: $@" if $@;
    warn "couldn't do $file: $!"    unless defined $config;
    warn "couldn't run $file"	    unless $config;
}
else{
    $registry->load_registry_from_db(
	-host => $config->{'db_registry'}{'host'},
	-user => $config->{'db_registry'}{'user'},
	-port => $config->{'db_registry'}{'port'},
    );
    #if there is command line input use that, else take the config file.
    GetOptions('species:s' => \$species);
    if(!defined $species){
	$species =$config->{'species'};
    }
}

my $log = Logger->new({
    healthcheck => 'MultipleComponentAssemblyMapping',
    type => $database_type,
    species => $species,
});

my $dba = $registry->get_DBAdaptor($species, $database_type);

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
);

my $result = 1;

my $array_ref = $helper->execute(
    -SQL => "SELECT * FROM coord_system",
    -CALLBACK => sub {
	my @row = @{ shift @_ };
	return { coord_system_id => $row[0], species_id => $row[1], name => $row[2],
		version => $row[3], rank => $row[4], attrib => $row[5] };
     },
);

my %name_version_to_id;
my %id_to_name_version;

foreach my $hash_ref (@$array_ref){
    my $coord_system_id = defined ${$hash_ref}{coord_system_id} ? ${$hash_ref}{coord_system_id} : 'NULL';
    #my $species_id = $ { $hash_ref } { species_id };
    my $name = defined ${$hash_ref}{name} ? ${$hash_ref}{name} : 'NULL';
    my $version = defined ${$hash_ref}{version} ? ${$hash_ref}{version} : 'NULL';
    #my $rank = $ { $hash_ref } { rank };
    #my $attrib = $ { $hash_ref } { attrib };
    
    if($version eq ""){
        $log->message("PROBLEM: Perl has found an empty string value in the version column; "
                       ."only NULL values or strings with length > 0 are allowed \n");
        next;
    }
    
    $name_version_to_id{"$name:$version"} = $coord_system_id;
    $id_to_name_version{$coord_system_id} = "$name:$version";
}
