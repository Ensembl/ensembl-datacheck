#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use Bio::EnsEMBL::DBSQL::DBAdaptor;

use DBUtils::RowCounter;
use DBUtils::MultiDatabase;

my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
       -host => 'ensembldb.ensembl.org',
       -user => 'anonymous',
       -port => 3306,    
);

my $sql = "SELECT * FROM coord_system WHERE name != 'lrg'";

my @database_types = ('core', 'cdna', 'otherfeatures', 'rnaseq');

my $types = \@database_types;

my $same = DBUtils::MultiDatabase::check_sql_across_species(
    sql => $sql,    
    registry => $registry,
    types => $types,
);

print "$same \n";
