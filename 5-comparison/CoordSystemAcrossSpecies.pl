=head1 NAME

  CoordSystemAcrossSpecies - A table comparison test across several databases (type 5 in the healthcheck system)

=head1 SYNOPSIS

  $ perl CoordSystemAcrossSpecies.pl --species 'homo sapiens'

=head2 DESCRIPTION

 --species 'species name'      : String (Optional) - name of the species to check on
 --config_file                 : String (Optional) - location of the config file relative to the working directory. Default
                                 is one folder above the working directory.

  Database type                : Core, cdna, otherfeatures, rnaseq.

If no command line input arguments are given, values from the 'config' file in the main directory will be used.

NOTE: This healthcheck requires the registry that contains the species to be loaded, as several different DBA's
for one species need to be retrieved. Make sure the use_direct_connection value in the config file is set to 0.
  
For a species the coord_system table should be the same across all he generic databases. This healthcheck
calls the check_same_sql_result with the sql and the database types as arguments. The function then retrieves all
the databases for the species from the registry and checks the tables between database.

Perl adaptation of the CoordSystemAcrossSpecies.java test.
See: https://github.com/Ensembl/ensj-healthcheck/blob/release/84/src/org/ensembl/healthcheck/testcase/generic/CoordSystemAcrossSpecies.java

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
use DBUtils::SqlComparer;

my $config_file;

GetOptions('config_file:s' => \$config_file);

my $dba = DBUtils::Connect::get_db_adaptor($config_file);

my $species = DBUtils::Connect::get_db_species($dba);

my $sql = "SELECT * FROM coord_system WHERE name != 'lrg'";

my @database_types = ('core', 'cdna', 'otherfeatures', 'rnaseq');

my $types = \@database_types;

my $log = Logger->new({
    healthcheck => 'CoordSystemAcrossSpecies',
    species => $species
});

my $result = 1;

$result &= DBUtils::SqlComparer::check_same_sql_result(
    sql => $sql,
    species => $species,
    types => $types,
    meta => 1,
    logger => $log,
);

#the final result is general case so change from the last database type used.
$log->type('undefined');

$log->result($result);
