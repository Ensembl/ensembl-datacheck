#!/usr/bin/env perl

use strict;
use warnings;

use lib '/home/ensembl/Shared_Folders/lib'; 
use DB::Registry;
use DB::Reference;

my $arrayref = [1, 2, ['a', [5, 7, 8], 'c'], 3];
DB::Reference::print_ref($arrayref);

DB::Registry::get_registry('ensembldb.ensembl.org', 'anonymous', 3306);
my $helper = DB::Registry::get_helper('Cavia porcellus', 'core');

my $sql_ref = $helper->execute(
	-SQL => "SELECT exon_id, seq_region_end, created_date FROM exon LIMIT 10",
);

DB::Reference::print_ref($sql_ref);


