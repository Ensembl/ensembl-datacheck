#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Registry;

my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
	-host => 'ensembldb.ensembl.org',
	-user => 'anonymous',
);

my $gene_adaptor = $registry->get_adaptor('Human', 'Core', 'Gene');
my $gene = $gene_adaptor->fetch_by_stable_id('ENSG00000139618');

my $dblinks = $gene->get_all_DBLinks('GO');

my $db_adaptor = $registry->get_adaptor('Multi', 'Ontology', 'OntologyTerm');

while (my $dblink = shift @{$dblinks}){
	my $term = $db_adaptor->fetch_by_accession($dblink->display_id);
	print $term->accession . " " . $term->name . "\n";
}
