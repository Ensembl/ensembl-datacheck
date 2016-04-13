package DBUtils::Connect;

use strict;
use warnings;

use File::Spec;
use Getopt::Long;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::DBSQL::DBConnection;

sub get_db_adaptor{
    my ($file) = @_;
   
    my $parent_dir = File::Spec->updir;
    
    $file ||= "$parent_dir/config";
    
    my $config = do $file;
    if(!$config){
        warn "couldn't parse $file: $@" if $@;
        warn "couldn't do $file: $!"    unless defined $config;
        warn "couldn't run $file"       unless $config; 
        die;
    }
    else {
        my $use_direct_connection = $config->{'use_direct_connection'};
        
        my $dba;
        
        if($use_direct_connection){
            $dba = _get_direct_con($config);
        }
        else{
            $dba = _get_registry_con($config);
        }
        if(!defined($dba)){
            warn "Not able to retrieve a database adaptor. It may be that the given database type isn't availalble for the species.";
            die;
        }
        return $dba;
    }
}

sub _get_direct_con{
     my ($config) = @_;
     
     #use dbadaptor instead?
     my $dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
        -user => $config->{'db_connection'}{'user'},
        -dbname => $config->{'db_connection'}{'dbname'},
        -host => $config->{'db_connection'}{'host'},
        -driver => $config->{'db_connection'}{'driver'},
        -pass => $config->{'db_connection'}{'pass'},
    );
    
    return $dba;
}

sub _get_registry_con{
    my ($config) = @_;
    
    my $registry = 'Bio::EnsEMBL::Registry';
    
    $registry->load_registry_from_db(
        -host => $config->{'db_registry'}{'host'},
        -user => $config->{'db_registry'}{'user'},
        -port => $config->{'db_registry'}{'port'},
    );
    
    my ($species, $database_type);
    
    #if there is command line input use that, else take the config file.
    GetOptions('species:s' => \$species, 'type:s' => \$database_type);
    if(!defined $species){
        $species = $config->{'db_registry'}{'species'};
    }
    if(!defined $database_type){
        $database_type = $config->{'db_registry'}{'database_type'};
    }
    
    my $dba = $registry->get_DBAdaptor($species, $database_type);

    return $dba;
}

sub get_db_species{
    my ($dba) = @_;
    
    my $species = $dba->species();
    
    if($species eq 'DEFAULT'){
        my $db_name = ($dba->dbc())->dbname();
        
        if($db_name =~ /([A-Za-z]+_[A-Za-z]+)/){
            $species = $1;
        }
    }
    
    return $species;
}

1;