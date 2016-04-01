
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

use DBUtils::SqlComparer;

my $registry = 'Bio::EnsEMBL::Registry';

my $parent_dir = File::Spec->updir;
my $file = $parent_dir. "/config";

my $config = do $file;
if(!$config){
    warn "couldn't parse $file: $@" if $@;
    warn "couldn't do $file: $!"    unless defined $config;
    warn "couldn't run $file"       unless $config;
}
else{
    $registry->load_registry_from_db(
           -host => $config->{'db_registry'}{'host'},
           -user => $config->{'db_registry'}{'user'},
           -port => $config->{'db_registry'}{'port'},
    );
}

my $sql = "SELECT * FROM coord_system WHERE name != 'lrg'";

my @database_types = ('core', 'cdna', 'otherfeatures', 'rnaseq');

my $types = \@database_types;

my $result = 1;

$result &= DBUtils::SqlComparer::check_sql_across_species(
    sql => $sql,    
    registry => $registry,
    types => $types,
    meta => 1,
);

print "$result \n";
