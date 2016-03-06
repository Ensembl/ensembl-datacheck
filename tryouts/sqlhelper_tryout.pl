#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
	-host => 'ensembldb.ensembl.org',
	-user => 'anonymous',
	-port => 3306,
);

my $dba = $registry->get_DBAdaptor('Cavia porcellus', 'core');

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
	-DB_CONNECTION => $dba->dbc()
);

my $array_ref = $helper->execute(
	-SQL => 'SELECT * FROM genome_statistics',	
);

use Data::Dumper;

print Dumper($array_ref), "\n";








