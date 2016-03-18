
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

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;


use DBUtils::SqlComparer;

my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
       -host => 'ensembldb.ensembl.org',
       -user => 'anonymous',
       -port => 3306,    
);

my $sql = "SELECT * FROM coord_system WHERE name != 'lrg'";

my @database_types = ('core', 'cdna', 'otherfeatures', 'rnaseq');

my $types = \@database_types;

my $same = DBUtils::SqlComparer::check_sql_across_species(
    sql => $sql,    
    registry => $registry,
    types => $types,
    meta => 1,
);

print "$same \n";
