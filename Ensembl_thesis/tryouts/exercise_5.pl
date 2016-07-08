#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Registry;

Bio::EnsEMBL::Registry->load_registry_from_db(
	-host => 'ensembldb.ensembl.org',
	-user => 'anonymous',
);

#5.a
my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor("Human", "Core", "Gene");

my $gene = $gene_adaptor->fetch_by_display_label("CSNK2A1");

my @transcripts = @{ $gene->get_all_Transcripts };
my @exons = @{ $gene->get_all_Exons };

print "The number of transcripts is " . scalar(@transcripts) . " and the number of exons is " . scalar(@exons) . "\n";

#5.b
my $exon_count = 0;

while (my $transcript = shift @transcripts) {
	my $t_id = $transcript->display_id;
	my @exons = @{ $transcript->get_all_Exons };

	$exon_count += scalar(@exons);	

	if ( $transcript->translation ){
		my $pep = $transcript->translateable_seq();
		print $t_id . " has " . scalar(@exons) . " exons and the translation " . $pep . "\n";
	}
	else {
		print $t_id . " has " . scalar(@exons) . " exons but no translations associated with it \n";
	}
}

print "The total number of exons is " . $exon_count . "\n";

