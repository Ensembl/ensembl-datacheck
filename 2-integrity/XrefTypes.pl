=head1 NAME

  XrefTypes - User-defined integrity test on xrefs (type 2 in the healthcheck system)

=head1 SYNOPSIS

  $ perl XrefTypes.pl 'cavia porcellus'

=head1 DESCRIPTION

  ARG[species]    : String - name of the species to check on.

  Database        : Core

Xrefs from the same (external) source should all be mapped to the same type of Ensembl object.

Perl adaptation of the XrefTypes.java test
See: https://github.com/Ensembl/ensj-healthcheck/blob/26644ee7982be37aef610afc69fae52cc70f5b35/src/org/ensembl/healthcheck/testcase/generic/XrefTypes.java

=cut

#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Getopt::Long;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use Logger;

my $registry = 'Bio::EnsEMBL::Registry';

my $parent_dir = File::Spec->updir;
my $file = $parent_dir . "/config";

my $species;

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
    GetOptions('species:s' => \$species);
    if(!defined $species){
        $species = $config->{'species'};
    }
} 

#only applies to core databases
my $dba = $registry->get_DBAdaptor($species, 'core');

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
);

my $log = Logger->new({
    healthcheck => 'XrefTypes',
    type => 'core',
    species => $species,
});

my $result = 1;

my $sql = "SELECT  x.external_db_id, ox.ensembl_object_type, COUNT(*), e.db_name 
          FROM object_xref ox, external_db e, xref x 
              LEFT JOIN transcript t ON t.display_xref_id = x.xref_id 
              WHERE x.xref_id = ox.xref_id 
              AND e.external_db_id = x.external_db_id 
              AND isnull(transcript_id) 
          GROUP BY x.external_db_id, ox.ensembl_object_type";

my $query_result = $helper->execute(
    -SQL => $sql
);


my $previous_id = -1;
my $external_db_id = 0;
my $previous_type = "";
my $object_type = " ";
my $external_db_name;

foreach my $row (@$query_result){
    if(defined $row->[0]){
        $external_db_id = $row->[0];
    }
    else{
        $result &= 0;
        $log->message("PROBLEM: external_db_id not defined!");
    }
    if(defined $row->[1]){
        $object_type = $row->[1];
    }
    else{
        $result &= 0;
        $log->message("PROBLEM: object_type not defined!");
    }
    if(defined $row->[3]){
        $external_db_name = $row->[3];
    }
    else{
        $result &= 0;
        $log->message("PROBLEM: external_db_name not defined!");
    }

    if($external_db_id == $previous_id){
        $log->message("PROBLEM: External DB with Id $external_db_id $external_db_name "
              . "is associated with $object_type as well as $previous_type");
        $result &= 0;
    }

    $previous_type = $object_type;
    $previous_id = $external_db_id;
}

$log->result($result);
    
