#!/usr/bin/env perl

use warnings;
use strict;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use DBUtils::CheckForOrphans;
use DBUtils::TableSets;
use DBUtils::RowCounter;

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
        
$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'external_synonym',
    col1 => 'xref_id',
    table2 => 'xref',
    col2 => 'xref_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'identity_xref',
    col1 => 'object_xref_id',
    table2 => 'object_xref',
    col2 => 'object_xref_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'supporting_feature',
    col1 => 'exon_id',
    table2 => 'exon',
    col2 => 'exon_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'translation',
    col1 => 'transcript_id',
    table2 => 'transcript',
    col2 => 'transcript_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'ontology_xref',
    col1 => 'object_xref_id',
    table2 => 'object_xref',
    col2 => 'object_xref_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'associated_xref',
    col1 => 'object_xref_id',
    table2 => 'object_xref',
    col2 => 'object_xref_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'associated_xref',
    col1 => 'xref_id',
    table2 => 'xref',
    col2 => 'xref_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'associated_xref',
    col1 => 'source_xref_id',
    table2 => 'xref',
    col2 => 'xref_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'dependent_xref',
    col1 => 'object_xref_id',
    table2 => 'object_xref',
    col2 => 'object_xref_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'dependent_xref',
    col1 => 'master_xref_id',
    table2 => 'xref',
    col2 => 'xref_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'dependent_xref',
    col1 => 'dependent_xref_id',
    table2 => 'xref',
    col2 => 'xref_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans_with_constraint(
    helper => $helper,
    table1 => 'gene_archive',
    col1 => 'peptide_archive_id',
    table2 => 'peptide_archive',
    col2 => 'peptide_archive_id',
    constraint => "gene_archive.peptide_archive_id != 0",
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'peptide_archive',
    col1 => 'peptide_archive_id',
    table2 => 'gene_archive',
    col2 => 'peptide_archive_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'stable_id_event',
    col1 => 'mapping_session_id',
    table2 => 'mapping_session',
    col2 => 'mapping_session_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'gene_archive',
    col1 => 'mapping_session_id',
    table2 => 'mapping_session',
    col2 => 'mapping_session_id',
    both_ways => 0,
);

#HERE SOME FUNCTIONS THAT STILL NEED PROGRAMMING

my @types = ("Gene", "Transcript", "Translation");
foreach my $type (@types){
    $test_result &= check_keys_by_ensembl_object_type(
	    helper => $helper,
		object => 'object_xref',
		type => $type,
	);
}

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'analysis_description',
    col1 => 'analysis_id',
    table2 => 'analysis',
    col2 => 'analysis_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'gene_attrib',
    col1 => 'attrib_type_id',
    table2 => 'attrib_type',
    col2 => 'attrib_type_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'transcript_attrib',
    col1 => 'attrib_type_id',
    table2 => 'attrib_type',
    col2 => 'attrib_type_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'translation_attrib',
    col1 => 'attrib_type_id',
    table2 => 'attrib_type',
    col2 => 'attrib_type_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'translation',
    col1 => 'end_exon_id',
    table2 => 'exon',
    col2 => 'exon_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'translation',
    col1 => 'start_exon_id',
    table2 => 'exon',
    col2 => 'exon_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'alt_allele',
    col1 => 'gene_id',
    table2 => 'gene',
    col2 => 'gene_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'marker_map_location',
    col1 => 'map_id',
    table2 => 'map',
    col2 => 'map_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'marker_map_location',
    col1 => 'marker_id',
    table2 => 'marker',
    col2 => 'marker_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'marker_map_location',
    col1 => 'marker_synonym_id',
    table2 => 'marker_synonym',
    col2 => 'marker_synonym_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'assembly',
    col1 => 'asm_seq_region_id',
    table2 => 'seq_region',
    col2 => 'seq_region_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'unmapped_object',
    col1 => 'unmapped_reason_id',
    table2 => 'unmapped_reason',
    col2 => 'unmapped_reason_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'unmapped_object',
    col1 => 'analysis_id',
    table2 => 'analysis',
    col2 => 'analysis_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans_with_constraint(
    helper => $helper,
    table1 => 'supporting_feature',
    col1 => 'feature_id',
    table2 => 'dna_align_feature',
    col2 => 'dna_align_feature_id',
    constraint => "supporting_feature.feature_type = 'dna_align_feature'",
);

$test_result &= DBUtils::CheckForOrphans::check_orphans_with_constraint(
    helper => $helper,
    table1 => 'supporting_feature',
    col1 => 'feature_id',
    table2 => 'protein_align_feature',
    col2 => 'protein_align_feature_id',
    constraint => "supporting_feature.feature_type = 'protein_align_feature'",
);

$test_result &= DBUtils::CheckForOrphans::check_orphans_with_constraint(
    helper => $helper,
    table1 => 'transcript_supporting_feature',
    col1 => 'feature_id',
    table2 => 'dna_align_feature',
    col2 => 'dna_align_feature_id',
    constraint => "transcript_supporting_feature.supporting_feature.feature_type = 'dna_align_feature'",
);

$test_result &= DBUtils::CheckForOrphans::check_orphans_with_constraint(
    helper => $helper,
    table1 => 'transcript_supporting_feature',
    col1 => 'feature_id',
    table2 => 'protein_align_feature',
    col2 => 'protein_align_feature_id',
    constraint => "transcript_supporting_feature.feature_type = 'protein_align_feature'",
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'density_feature',
    col1 => 'density_type_id',
    table2 => 'density_type',
    col2 => 'density_type_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'prediction_exon',
    col1 => 'prediction_exon_id',
    table2 => 'prediction_transcript',
    col2 => 'prediction_transcript_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'marker',
    col1 => 'display_marker_synonym_id',
    table2 => 'marker_synonym',
    col2 => 'marker_synonym_id',
    both_ways => 0,
);

$test_result &= DBUtils::CheckForOrphans::check_orphans(
    helper => $helper,
    table1 => 'unmapped_object',
    col1 => 'external_db_id',
    table2 => 'external_db',
    col2 => 'external_db_id',
    both_ways => 0,
);

my @

print "$test_result \n";

my @analysis_tables = @{ DBUtils::TableSets::get_tables_with_analysis_id() };

foreach my $analysis_table (@analysis_tables){

	if($analysis_table eq 'protein_align_feature' || $analysis_table eq 'dna_align_feature'
	   || $analysis_table eq 'repeat_feature'){
        continue;	   
	}
	
	my $constraint = "analysis_id IS NOT NULL";
	if($analysis_table eq 'object_xref'){
		$constraint .= " and $analysis_table.analysis_id != 0";
	}
	
	$test_result &= $test_result &= DBUtils::CheckForOrphans::check_orphans_with_constraint(
    helper => $helper,
    table1 => $analysis_table,
    col1 => 'analysis_id',
    table2 => 'analysis',
    col2 => 'analysis_id',
    constraint => $constraint,
    );

}

$test_result &= check_display_marker_synonym_id($helper);

sub check_keys_by_ensembl_object_type{
	my ($arg_for) = @_;
	
	my $helper = $arg_for->{helper};
	my $object = $arg_for{object};
	my $type = $arg_for{type};
	
	#find camelcase capital letters and separate them by _ instead and convert to lower case.
	my $table =~ s/([a-z])([A-Z])/$1_$2/;
	$table = lc($able);
	
	my $column;
	if($object eq 'object_xref'){
		$column = 'ensembl_id';
	}
	else{
		$column = 'ensembl_object_id';
	}
	
	my $result = DBUtils::CheckForOrphans::check_orphans_with_constraint(
    helper => $helper,
    table1 => $object,
    col1 => $column,
    table2 => $table,
    col2 => $table . "_id",
    constraint => "$object.ensembl_object_type = \'$type\'",
    );
	
	return $result;
}

sub check_display_marker_synonym_id{
	my ($helper) = @_;
	
	my $result = 1;
	
	my $sql = "SELECT COUNT(*) FROM marker m " 
	           . "WHERE m.display_marker_synonym_id NOT IN "
			       . "(SELECT ms.marker_synonym_id FROM marker_synonym ms "
				         . "WHERE m.marker_id = ms.marker_id)";
	
	my $number_of_rows = DBUtils::RowCounter::get_row_count({
    helper => $helper,
    sql => $sql,
	});
	
	if ($number_of_rows > 0)
		$result = 0;
		print "I need a better error message. Greetings from check_display_marker_synonym_id \n";
	}
	
	return $result;
}
