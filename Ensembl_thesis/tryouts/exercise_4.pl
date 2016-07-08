#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Registry;

my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
	-host => 'ensembldb.ensembl.org',
	-user => 'anonymous',
);

#4.a
my $slice_adaptor = $registry->get_adaptor('Human', 'Core', 'Slice');

my $slice = $slice_adaptor->fetch_by_region('chromosome', '20', 1, 50e4);

my @repeat_feats = @{$slice->get_all_RepeatFeatures};

print "The total number of features is: " . scalar(@repeat_feats) . "\n";

while (my $repeat_feat = shift @repeat_feats){
	#print "The features name is: " . $repeat_feat->display_id;
	#print " and its position is: " . $repeat_feat->start . "\n";
}

#4.b
my $dafa = $registry ->get_adaptor('Human', 'Core', 'DnaAlignFeature');

my @features = @{ $dafa->fetch_all_by_hit_name('NM_000059.3') };

while (my $feature = shift @features){
	#this part is not right/finished
	my $seq_name = $feature->seq_region_name;
	my $seq_start = $feature->seq_region_start;
	my $seq_stop = $feature->seq_region_end;
	print "The region name is " . $seq_name . " and ranges from " . $seq_start . " to " . $seq_stop . "\n";
}


