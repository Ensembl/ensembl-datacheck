#!/usr/bin/env perl

use strict;
use warnings;

#An attempt to implement the RepeatFeature.java test with the Ensembl Perl API

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
	-DB_CONNECTION => $dba->dbc(),
);

#see how long the query takes.not very precise though
my $start_query = time();

#count no. start > end
my $bigger_start_ref = $helper->execute(
	-SQL => 'SELECT COUNT(*) FROM repeat_feature WHERE repeat_start > repeat_end',
);

#count no. of negatives for start and/or end
my $negative_location_ref = $helper->execute(
	-SQL => 'SELECT COUNT(*) FROM repeat_feature WHERE repeat_start < 1 OR repeat_end < 1',
);

my $end_query = time();

my $query_time = $end_query - $start_query;

print "Query took $query_time seconds \n";

if($bigger_start_ref->[0][0] == 0){
	print "All repeat_feature rows have repeat_start < repeat__end \n";
}
else{
	#later on also print this to a log file with more info
	print $bigger_start_ref->[0][0] . " rows in repeat_feature have repeat_start > repeat_end \n";
}

if($negative_location_ref->[0][0] == 0){
	print "All repeat_feature rows have repeat_start and repeat_end > 1 \n";
}
else{
	#later on also print this to a log file with more info
	print $negative_location_ref->[0][0] . " rows in repeat_feature have repeat_start or repeat_end < 1 \n";
}



