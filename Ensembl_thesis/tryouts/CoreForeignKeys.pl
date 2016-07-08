#!/usr/bin/env perl

use lib '/home/ensembl/Shared_Folders/lib';

use DB::Registry;
use DB::Reference;
use DB::CheckForOrphans;

DB::Registry::get_registry('ensembldb.ensembl.org', 'anonymous', 3306);

my $helper = DB::Registry::get_helper('Cavia porcellus', 'core');

my $test_result = 1;

$test_result &= DB::CheckForOrphans::count_orphans(
  helper => $helper,
  table1 => 'exon',
  col1   => 'exon_id',
  table2 => 'exon_transcript',
  col2   => 'exon_id'
);

$test_result &= DB::CheckForOrphans::count_orphans(
  helper => $helper,
  table1 => 'transcript',
  col1   => 'transcript_id',
  table2 => 'exon_transcript',
  col2   => 'transcript_id'
);

$test_result &= DB::CheckForOrphans::count_orphans(
  helper => $helper,
  table1 => 'gene',
  col1   => 'gene_id',
  table2 => 'transcript',
  col2   => 'gene_id'
);

if($test_result){
  print "THE CoreForeignKeys TEST RAN SUCCESFULLY: NO PROBLEMS. \n";
}
else{
  print "THE CoreForeignKeys TEST DETECTED FOREIGN KEY VIOLATIONS. \n";
}
