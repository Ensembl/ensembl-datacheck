
=head1 NAME

  ProjectedXrefs - A user-defined integrity test (type 2 in the healthcheck system).

=head2 SYNOPSIS

  $ perl ProjectedXrefs.pl 'canis familiaris' 'core'

=head3 DESCRIPTION

  ARG[Species Name]      : String - Name of the species to test on.
  ARG[Database type]     : String - Type of the database to run on.
  
  Database type          : Core

Checks that the species that should have them have xrefs projected on genes, and have projected GO
xrefs.

Perl adaptation of the ProjectedXrefs.java test.
See: https://github.com/Ensembl/ensj-healthcheck/blob/release/83/src/org/ensembl/healthcheck/testcase/generic/ProjectedXrefs.java

=cut

#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Getopt::Long;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use DBUtils::RowCounter;

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

#Find the proper species name. Needed later for filtering. 
my $proper_species = $registry->get_alias($species);

my $dba = $registry->get_DBAdaptor($proper_species, 'core');

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
);

my $result = 1;

if($proper_species eq 'homo_sapiens' ||
   $proper_species eq 'caenorhabditis_elegans' ||
   $proper_species eq 'drosophila_melanogaster' ||
   $proper_species eq 'saccharomyces_cerevisiae' ||
   $proper_species eq 'ciona_intestinalis' ||
   $proper_species eq 'ciona_savignyi'){
    #no testing for these species
    print "Test is not needed for " . $species ."\n";
}
else{
    #find the number of genes with projected xrefs.
    my $xref_sql = "SELECT COUNT(*) FROM gene g, xref x
                       WHERE g.display_xref_id = x.xref_id
                       AND x.info_type = 'PROJECTION'";

    my $xref_rows = DBUtils::RowCounter::get_row_count({
        helper => $helper,
        sql => $xref_sql,
    });

    if($xref_rows == 0){
        print "PROBLEM: No genes in " . $species . " have projected display_xrefs. \n";
        $result = 0;
    }
    else{
        print "OK: " . $xref_rows . " genes in " . $species . " have projected display_xrefs. \n";
    }

    #find the number of projected GO xrefs.
    my $go_sql = "SELECT COUNT(*) FROM xref x, external_db e
                     WHERE e.external_db_id = x.external_db_id
                     AND e.db_name = 'GO'
                     AND x.info_type = 'PROJECTION'";

    my $go_rows = DBUtils::RowCounter::get_row_count({
        helper => $helper,
        sql => $go_sql,
    });

    if($go_rows == 0){
        print "PROBLEM: No projected GO terms in " . $species . "\n";
        $result = 0;
    }
    else{
        print "OK: " . $go_rows . " projected GO terms in " . $species ."\n";
   }
}

print $result . "\n"
