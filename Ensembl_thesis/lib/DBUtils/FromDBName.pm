=head1 NAME

  DBUtils::FromDBName

=head1 SYNOPSIS

  my $species = DBUtils::FromDBName::get_species($dba);
  my $database_type = DBUtils::FromDBName::get_type($dba);
  my $version = DBUtils::FromDBName::get_version($dba);
  my $gene_build = DBUtils::FromDBName::get_gene_build($dba);
 
=head1 DESCRIPTION

A module that retrieves information about the database using the database name.

Adapted rom DatabaseRegistryEntry.java. Alterations: new regexs for stable_ids database (ESI-DB), correction on EM_DB. 
See: https://github.com/Ensembl/ensj-healthcheck/blob/release/84/src/org/ensembl/healthcheck/DatabaseRegistryEntry.java

=cut

package DBUtils::FromDBName;



use strict;
use warnings;

    #e.g. username_species_type
    my $GB_DB = qr/^[a-z0-9]+_([a-z]+)_([A-Za-z]+)/;
    #e.g. neurospora_crassa_core_4_56_1a
    my $EG_DB = qr/^([a-zA-Z0-9_]+)_([a-z]+)_[0-9]+_([0-9]+)_([0-9A-Za-z]+)/;
    #e.g. homo_sapiens_core_56_37a
    my $E_DB = qr/^([a-z_]+)_([a-z]+)_([0-9]+)_([0-9A-Za-z]+)/;
    #e.g. prefix_homo_sapiens_funcgen_60_37e
    my $PE_DB = qr/^[^_]+_([^_]+_[^_]+)_([a-z]+)_([0-9]+)_([0-9A-Za-z]+)/;
    #e.g. human_core_20, hsapiens_XXX
    my $EEL_DB = qr/^([^_]+)_([a-z]+)_([0-9]+)/;
    #e.g. ensembl_compara_bacteria_3_56
    my $EGC_DB = qr/^(ensembl)_(compara)_[a-z_]+_[0-9]+_([0-9]+)/;
    #e.g. ensembl_compara_56
    my $EC_DB = qr/^(ensembl)_(compara)_([0-9]+)/;
    #e.g. username_ensembl_compara_57
    my $UC_DB = qr/^[^_]+_(ensembl)_(compara)_([0-9]+)/;
    #e.g. username_ensembl_compara_master
    my $UCM_DB = qr/^[^_]+_(ensembl)_(compara)_master/;
    #e.g. ensembl_ancestral_57
    my $EA_DB = qr/^(ensembl)_(ancestral)_([0-9]+)/;
    #e.g. username_ensembl_ancestral_57
    my $UA_DB = qr/^[^_]+_(ensembl)_(ancestral)_([0-9]+)/;
    #e.g. ensembl_stable_ids_84
    my $ESI_DB = qr/^(ensembl)_(stable_ids)_([0-9]+)/;
    #e.g. ensembl_mart_56
    my $EM_DB = qr/^([a-z_]+)_(mart)_([0-9]+)/;
    my $V_DB = qr/vega_([^_]+_[^_]+)_[^_]+_([^_]+)_([^_]+)/;
    my $EE_DB = qr/^([^_]+_[^_]+)_[a-z]+_([a-z]+)_[a-z]+_([0-9]+)_([0-9A-Za-z]+)/;
    my $U_DB = qr/^[^_]+_([^_]+_[^_]+)_([a-z]+)_([0-9]+)_([0-9A-Za-z]+)/;
    my $HELP_DB = qr/^(ensembl)_(help)_([0-9]+)/;
    my $EW_DB = qr/^(ensembl)_(website)_([0-9]+)/;
    my $TAX_DB = qr/^(ncbi)_(taxonomy)_([0-9]+)/;
    my $UD_DB = qr/^([a-z_]+)_(userdata)/;
    my $BLAST_DB = qr/^([a-z_]+)_(blast)/;
    my $MASTER_DB = qr/^(master_schema)_([a-z]+)?_([0-9]+)/;
    my $MYSQL_DB = qr/^(mysql|information_schema)/;
    
    my @ordered_regexs = ($EC_DB, $UA_DB, $UC_DB, $UCM_DB, $EA_DB,
        $EGC_DB, $ESI_DB, $EG_DB, $E_DB, $PE_DB, $EM_DB, $EEL_DB, $U_DB,
        $V_DB, $MYSQL_DB, $BLAST_DB, $UD_DB, $TAX_DB, $EW_DB, $HELP_DB, $GB_DB, $MASTER_DB);


=head2 get_species

  ARG[adaptor]     : EnsEMBL::DBSQL::DBAdaptor instance.
  
  Returntype       : String (species name)
  
Extracts the species from the database name through regular expressions.
  
=cut        
        
sub get_species{
    my ($dba) = @_;
    my $species;
    
    my $dbname = _db_name($dba);

    foreach my $regex (@ordered_regexs){
        if($dbname =~ $regex){
            $species = $1;
            last;
        }
    }
    
    if(!defined $species){
        $species = 'UNKNOWN';
    }
    
    return $species;
}

=head2 get_type

  ARG[adaptor]     : EnsEMBL::DBSQL::DBAdaptor instance.
  
  Returntype       : String (database type)
  
Extracts the database type from the database name through regular expressions.
  
=cut 

sub get_type{
    my ($dba) = @_;
    my $type;
    
    my $dbname = _db_name($dba);
    
    foreach my $regex (@ordered_regexs){
        if($dbname =~ $regex){
            $type = $2;
            last;
        }
    }
    
    if(!defined $type){
        $type = 'UNKNOWN';
    }
    
    return $type;
}

=head2 get_version

  ARG[adaptor]     : EnsEMBL::DBSQL::DBAdaptor instance.
  
  Returntype       : String (release version)
  
Extracts the database release version from the database name through regular expressions.
  
=cut 

sub get_version{
    my ($dba) = @_;
    my $version;
    
    my $dbname = _db_name($dba);
   
    foreach my $regex (@ordered_regexs){
        if($dbname =~ $regex){
            $version = $3;
            last;
        }
    }
    
    if(!defined $version){
        $version = 'UNKNOWN';
    }
    
    return $version;
}

=head2 get_gene_build

  ARG[adaptor]     : EnsEMBL::DBSQL::DBAdaptor instance.
  
  Returntype       : String (gene build/assembly)
  
Extracts the gene build/assembly from the database name through regular expressions.
  
=cut 

sub get_gene_build{
    my ($dba) = @_;
    my $gene_build;
    
    my $dbname = _db_name($dba);

    foreach my $regex (@ordered_regexs){
        if($dbname =~ $regex){
            if(defined $4){
                $gene_build = $4;
            }
            last;
        }
    }
     
     if(!defined $gene_build){
        $gene_build = 'UNKOWN';
     }
     
     return $gene_build;
}     


=head2 _db_name

  ARG[adaptor]     : EnsEMBL::DBSQL::DBAdaptor instance.
  
  Returntype       : String (database name)
  
Returns the database name corresponding to the DBAdaptor input argument.
  
=cut 

sub _db_name{
    my ($dba) = @_;
    
    my $dbname = ($dba->dbc())->dbname();
    
    return $dbname;
}

1;