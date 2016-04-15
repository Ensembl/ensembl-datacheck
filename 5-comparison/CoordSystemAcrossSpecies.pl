
=head1 NAME

  CoordSystemAcrossSpecies - A table comparison test across several databases (type 5 in the healthcheck system)

=head1 SYNOPSIS

  $ perl CoordSystemAcrossSpecies.pl

=head2 DESCRIPTION

  Database type     : Core, cdna, otherfeatures, rnaseq.

For each species the coord_system table should be the same across all he generic databases. This healthcheck
calls the check_sql_species with the sql and the database types as arguments. The function then retrieves all
the species from the registry and checks the tables between databases for each of them.

Perl adaptation of the CoordSystemAcrossSpecies.java test.
See: https://github.com/Ensembl/ensj-healthcheck/blob/release/84/src/org/ensembl/healthcheck/testcase/generic/CoordSystemAcrossSpecies.java

=cut

#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Getopt::Long;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use Logger;
use DBUtils::Connect;
use DBUtils::SqlComparer;

#we don't care about the adaptor we get back from this
my $dba = DBUtils::Connect::get_db_adaptor();

my $species = DBUtils::Connect::get_db_species($dba);
my $database_type = $dba->group();
print "$species $database_type \n";

my $registry = 'Bio::EnsEMBL::Registry';

my $sql = "SELECT * FROM coord_system WHERE name != 'lrg'";

my @database_types = ('core', 'cdna', 'otherfeatures', 'rnaseq');

my $types = \@database_types;

my $log = Logger->new({
    healthcheck => 'CoordSystemAcrossSpecies',
});

my $result = 1;

$result &= DBUtils::SqlComparer::check_sql_across_species(
    sql => $sql,    
    registry => $registry,
    types => $types,
    meta => 1,
    logger => $log,
);

#the final result is general case so change from the last species & database type used.
$log->type('undefined');
$log->species('undefined');

$log->result($result);
