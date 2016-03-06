#!usr/bin/env perl

use strict;
use warnings;

use lib '/home/ensembl/Shared_Folders/lib';

use DB::Registry;
use DB::Reference;

DB::Registry::get_registry('ensembldb.ensembl.org', 'anonymous', 3306);

my $helper = DB::Registry::get_helper('Homo sapiens', 'core');

my $sql = "SELECT aa.alt_allele_group_id, GROUP_CONCAT(
              DISTINCT CONCAT(IFNULL(ae.exc_seq_region_id, -1),',', g.seq_region_id, ',', IFNULL(ae.exc_type, 'NULL')) SEPARATOR ';') 
              AS seq_regions 
           FROM alt_allele_group aag 
              LEFT JOIN alt_allele aa ON aa.alt_allele_group_id = aag.alt_allele_group_id 
              LEFT JOIN gene g ON aa.gene_id = g.gene_id 
              LEFT JOIN seq_region sr ON g.seq_region_id = sr.seq_region_id 
              LEFT JOIN assembly_exception ae ON g.seq_region_id = ae.seq_region_id 
           GROUP BY alt_allele_group_id
           LIMIT 10";

$result = $helper->execute(
    -SQL => $sql,
);

DB::Reference::print_ref($result);




