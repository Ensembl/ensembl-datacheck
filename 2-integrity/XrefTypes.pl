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

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

my $species = $ARGV[0];

my $registry = 'Bio::EnsEMBL::Registry';

#This should probably be configurable as well. Config file?
$registry->load_registry_from_db(
    -host => 'ensembldb.ensembl.org',
    -user => 'anonymous',
    -port => 3306,
);

#only applies to core databases
my $dba = $registry->get_DBAdaptor($species, 'core');

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
);

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

#my @query_result = ( ['12600', 'Gene', '13054', 'WikiGene'], ['12700', 'Translation', '84411', 'goslim_goa'],
#                  ['20005', 'Translation', '19774', 'UniParc'], ['20005', 'Gene', '289', 'UniParc'] );

#my $query_result = \@query_result;

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
        die "PROBLEM: external_db_id not defined! \n";
    }
    if(defined $row->[1]){
        $object_type = $row->[1];
    }
    else{
        die "PROBLEM: object_type not defined! \n";
    }
    if(defined $row->[3]){
        $external_db_name = $row->[3];
    }
    else{
        die "PROBLEM: external_db_name not defined! \n";
    }

    if($external_db_id == $previous_id){
        print "External DB with Id $external_db_id $external_db_name "
              . "is associated with $object_type as well as $previous_type \n";
        $result = 0;
    }

    $previous_type = $object_type;
    $previous_id = $external_db_id;
}

print "$result \n";
    
