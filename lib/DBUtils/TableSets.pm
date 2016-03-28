package DBUtils::TableSets

use strict;
use warnings;

my @feature_tables = ("assembly_exception", "gene", "exon",
			"dna_align_feature", "protein_align_feature", "repeat_feature",
			"simple_feature", "marker_feature", "misc_feature",
			"karyotype", "transcript", "density_feature", "prediction_exon",
			"prediction_transcript", "ditag_feature");
			
my @tables_with_analysis_id = ("gene", "protein_feature",
			"dna_align_feature", "protein_align_feature", "repeat_feature",
			"prediction_transcript", "simple_feature", "marker_feature",
			"density_type", "object_xref", "transcript",
            "intron_supporting_evidence", "operon",  "operon_transcript", 
			"unmapped_object", "ditag_feature", "data_file");
			
my @funcgen_feature_tables = ("probe_feature",
			"annotated_feature", "regulatory_feature", "external_feature",
			"motif_feature", "mirna_target_feature", "segmentation_feature");
			
my @funcgen_tables_with_analysis_id = ("probe_feature",
			"object_xref", "unmapped_object", "feature_set", "result_set");
			

sub get_feature_tables{
    return @feature_tables;
}

sub get_tables_with_analysis_id{
    return @tables_with_analysis_id;
}

sub get_funcgen_feature_tables{
    return @funcgen_feature_tables;
}

sub get_tables_with_analysis_id{
	return @funcgen_tables_with_analysis_id;
}