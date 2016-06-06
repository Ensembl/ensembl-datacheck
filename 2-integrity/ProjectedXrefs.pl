
=head1 NAME

  ProjectedXrefs - A user-defined integrity test (type 2 in the healthcheck system).

=head2 SYNOPSIS

  $ perl ProjectedXrefs.pl --species 'canis familiaris' --type 'core'

=head3 DESCRIPTION

  --species 'species name'     : String - Name of the species to test on.
  --type 'database type'       : String - Type of the database to run on.
  --config_file                : String (Optional) - location of the config file relative to the working directory. Default
                                 is one folder above the working directory.
                                 
  Database type                : Core
  
If no command line input arguments are given, values from the 'config' file in the parent directory of the working directory will be used.

Checks that the species that should have them have xrefs projected on genes, and have projected GO
xrefs.

Perl adaptation of the ProjectedXrefs.java test.
See: https://github.com/Ensembl/ensj-healthcheck/blob/release/83/src/org/ensembl/healthcheck/testcase/generic/ProjectedXrefs.java

=cut

#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Getopt::Long qw(:config pass_through);

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use Logger;
use DBUtils::RowCounter;
use DBUtils::Connect;

my $config_file;

GetOptions('config_file:s' => \$config_file);

my $dba = DBUtils::Connect::get_db_adaptor($config_file);

my $species = DBUtils::Connect::get_db_species($dba);

my $database_type = $dba->group();

my $log = Logger->new({
    healthcheck => 'ProjectedXrefs',
    type => 'core',
    species => $species,
});

if(lc($database_type) ne 'core'){
    $log->message("WARNING: this healthcheck only applies to core databases. Problems in execution will likely arise");
}

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
);


my $result = 1;

if($species eq 'homo_sapiens' ||
   $species eq 'caenorhabditis_elegans' ||
   $species eq 'drosophila_melanogaster' ||
   $species eq 'saccharomyces_cerevisiae' ||
   $species eq 'ciona_intestinalis' ||
   $species eq 'ciona_savignyi'){
    #no testing for these species
    $log->message("SKIPPING: Test is not needed for " . $species);
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
        $log->message("PROBLEM: No genes in " . $species . " have projected display_xrefs.");
        $result = 0;
    }
    else{
        $log->message("OK: " . $xref_rows . " genes in " . $species . " have projected display_xrefs.");
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
        $log->message("PROBLEM: No projected GO terms in " . $species);
        $result = 0;
    }
    else{
        $log->message("OK: " . $go_rows . " projected GO terms in " . $species);
   }
}

$log->result($result);
