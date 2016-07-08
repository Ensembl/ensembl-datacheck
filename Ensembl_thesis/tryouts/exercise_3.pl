#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use Bio::SeqIO;

my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
	-host => 'ensembldb.ensembl.org',
	-user => 'anonymous',
);

my $slice_adaptor = $registry->get_adaptor('Human','Core','Slice');
my @slices = @{$slice_adaptor->fetch_all('chromosome')};
print scalar(@slices) . "\n";

while (my $slice = shift @slices ){
	print "The chromosome name is: " . $slice->name();
	print " and its length is: " . $slice->length() . "\n";
}

my $stable_gen = $slice_adaptor->fetch_by_gene_stable_id('ENSG00000101266', 2e3);

my $chrom_20 = $slice_adaptor->fetch_by_region('chromosome', '20', 0, 10e6);

my $output = Bio::SeqIO->new( -file =>'>chrom_20.fasta', -format =>'Fasta');
$output->write_seq($chrom_20);

my @genes_in_20 = @{$chrom_20->get_all_Genes};
print "The number of genes in chromosome 20 is " . scalar(@genes_in_20);
