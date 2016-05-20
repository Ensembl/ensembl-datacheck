=head1 NAME

  DBUtils::Connect
  
=head1 SYNOPSIS

  my $dba = DBUtils::Connect::get_db_adaptor();
  
  my $species = DBUtils::Connect::get_db_species($dba);
  
=head1 DESCRIPTION

A module for connection to a database either through the registry or directly.

=cut

package DBUtils::Connect;

use strict;
use warnings;

use File::Spec;
use Getopt::Long;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::DBSQL::DBConnection;
use Bio::EnsEMBL::Utils::Exception qw ( throw warning );


=head2 get_db_adaptor

  ARG[file location]    : Optional. Location of the config file to get values from. Default is 'config',
                          one directory above the current working directory (assuming you're in i.e. 1-integrity).
  
  Returntype            : EnsEMBL::DBSQL::DBAdaptor instance.
  
Loads the config file. Then, depending on the value of use_direct_connection, connects directly to the database
through _get_direct_con (when use_direct_connection is 1), or through the registry with _get_registry_con (when
use_direct_connection is 0).

=cut

sub get_db_adaptor{
    my ($file) = @_;
   
    my $parent_dir = File::Spec->updir;
    
    $file ||= File::Spec->catfile(("$parent_dir"), "config");
    
    my $config = do $file;
    if(!$config){
        throw("couldn't parse $file: $@") if $@;
        throw("couldn't do $file: $!")    unless defined $config;
        throw("couldn't run $file")       unless $config; 
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
            throw("Not able to retrieve a database adaptor. It may be that the database type isn't availalble for the species.");
        }
        return $dba;
    }
}

=head2 _get_direct_con

    ARG[file]        : A loaded file with database connection information
    
    Returntype       : EnsEMBL::DBSQL::DBAdaptor instance.
    
Retrieves a DBAdaptor using the information in the db_connection hash in the config file.

=cut

sub _get_direct_con{
     my ($config) = @_;
     
     #use dbadaptor instead?
     my $dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
        -user => $config->{'db_connection'}{'user'},
        -dbname => $config->{'db_connection'}{'dbname'},
        -host => $config->{'db_connection'}{'host'},
        -driver => $config->{'db_connection'}{'driver'},
        -pass => $config->{'db_connection'}{'pass'},
        -port => $config->{'db_connection'}{'port'},
    );
    
    return $dba;
}

=head2 _get_registry_con

    ARG[file]        : A loaded file with database connection information
    
    Returntype       : EnsEMBL::DBSQL::DBAdaptor instance.
    
Loads the registry specified in the db_registry hash in the config file. Then retrieves a DBAdaptor using information
in the db_registry hash, or command line input (command line input overrides config file values).

=cut

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

=head2 get_db_species

  ARG[adaptor]     : EnsEMBL::DBSQL::DBAdaptor instance.
  
  Returntype       : String (species name)
  
Retrieves the species name that the adaptor belongs to. Uses the DBUtils::FromDBName module
if the Adaptor method species() doesn't return something useful.

=cut

use DBUtils::FromDBName;

sub get_db_species{
    my ($dba) = @_;
    
    my $species = $dba->species();
    
    if($species eq 'DEFAULT'){
        $species = DBUtils::FromDBName::get_species($dba);
    }
    
    return $species;
}

sub get_db_type{
    my ($dba)= @_;
    
    my $type = $dba->group();
    
    if($type eq 'none_standard'){
        $type = DBUtils::FromDBName::get_type($dba);
    }
    
    return $type;
}    

1;