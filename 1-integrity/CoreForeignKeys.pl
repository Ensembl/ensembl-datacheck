#!/usr/bin/env perl

use warnings;
use strict;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use DBUtils::CheckForOrphans;

my $species = $ARGV[0];
my $database_type = $ARGV[1];

my $registry = 'Bio::EnsEMBL::Registry';

#This should probably be configurable as well. Config file?
$registry->load_registry_from_db(
    -host => 'ensembldb.ensembl.org',
    -user => 'anonymous',
    -port => 3306,
);

my $dba = $registry->get_DBAdaptor($species, $database_type);

    my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
    );

my $test_result = 1;

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'exon',
    col1   => 'exon_id',
    table2 => 'exon_transcript',
    col2   => 'exon_id',
    both_ways => 1,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'transcript',
    col1   => 'transcript_id',
    table2 => 'exon_transcript',
    col2   => 'transcript_id',
    both_ways => 1,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'gene',
    col1   => 'gene_id',
    table2 => 'transcript',
    col2   => 'gene_id',
    both_ways => 1,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'object_xref',
    col1 => 'xref_id',
    table2 => 'xref',
    col2 => 'xref_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'xref',
    col1 => 'external_db_id',
    table2 => 'external_db',
    col2 => 'external_db_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'dna',
    col1 => 'seq_region_id',
    table2 => 'seq_region',
    col2 => 'seq_region_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'seq_region',
    col1 => 'coord_system_id',
    table2 => 'coord_system',
    col2 => 'coord_system_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'assembly',
    col1 => 'cmp_seq_region_id',
    table2 => 'seq_region',
    col2 => 'seq_region_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'marker_feature',
    col1 => 'marker_id',
    table2 => 'marker',
    col2 => 'marker_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'seq_region_attrib',
    col1 => 'seq_region_id',
    table2 => 'seq_region',
    col2 => 'seq_region_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'seq_region_attrib',
    col1 => 'attrib_type_id',
    table2 => 'attrib_type',
    col2 => 'attrib_type_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'misc_feature_misc_set',
    col1 => 'misc_feature_id',
    table2 => 'misc_feature',
    col2 => 'misc_feature_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'misc_feature_misc_set',
    col1 => 'misc_set_id',
    table2 => 'misc_feature',
    col2 => 'misc_set_id',
    both_ways => 0,
);

if($database_type eq 'sangervega'){
    $test_result &= DBUtils::CheckForOrphans::check_orphans_with_constraint(
                        helper => $helper,
                        table1 => 'misc_feature',
                        col1 => 'misc_feature_id',
                        table2 => 'misc_attrib',
                        col2 => 'misc_feature_id',
                        constraint => "misc_feature.misc_feature_id NOT IN " .
                                          "(SELECT mfms.misc_feature_id FROM misc_feature_misc_set AS mfms "
                                            . "JOIN misc_set AS ms ON mfms.misc_set_id = ms.misc_set_id "
                                            .  "AND ms.code = 'noAnnotation')",
                     );
}
else {
    $test_result &= DBUtils::CheckForOrphans::check_orphans(
        helper => $helper,
        table1 => 'misc_feature',
        col1 => 'misc_feature_id',
        table2 => 'misc_attrib',
        col2 => 'misc_feature_id',
        both_ways => 0,
    );
}

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'misc_attrib',
    col1 => 'attrib_type_id',
    table2 => 'attrib_type',
    col2 => 'attrib_type_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'assembly_exception',
    col1 => 'seq_region_id',
    table2 => 'seq_region',
    col2 => 'seq_region_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'assembly_exception',
    col1 => 'exc_seq_region_id',
    table2 => 'seq_region',
    col2 => 'seq_region_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'protein_feature',
    col1 => 'translation_id',
    table2 => 'translation',
    col2 => 'translation_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'marker_synonym',
    col1 => 'marker_id',
    table2 => 'marker',
    col2 => 'marker_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'translation_attrib',
    col1 => 'translation_id',
    table2 => 'translation',
    col2 => 'translation_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'transcript_attrib',
    col1 => 'transcript_id',
    table2 => 'transcript',
    col2 => 'transcript_id',
    both_ways => 0,
);
        

print "$test_result \n";





