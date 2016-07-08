=head1 NAME

  Input::AutoIncrement - containts the table-column pairs that should be set to autoincrement.
  
=head1 SYNPOSIS

  use Input::AutoIncrement;
  my @columns = @Input::AutoIncrement::AI_columns;

=head1 DESCRIPTION

  Contains the table-column pairs that are used by the AutoIncrement healthcheck to check if they are
  set to auto_increment. Add or delete from the array as desired.
  
=cut

package Input::AutoIncrement;

use strict;
use warnings;

our @AI_columns = ("alt_allele.alt_allele_id", "analysis.analysis_id", "assembly_exception.assembly_exception_id", 
               "attrib_type.attrib_type_id", "coord_system.coord_system_id", "data_file.data_file_id",  
               "density_feature.density_feature_id", "density_type.density_type_id", "ditag.ditag_id", 
               "ditag_feature.ditag_feature_id", "dna_align_feature.dna_align_feature_id", "exon.exon_id", 
               "external_db.external_db_id", "gene.gene_id", "intron_supporting_evidence.intron_supporting_evidence_id", 
               "karyotype.karyotype_id", "map.map_id", "mapping_session.mapping_session_id", "marker.marker_id", 
               "marker_feature.marker_feature_id", "marker_synonym.marker_synonym_id", "meta.meta_id", 
               "misc_feature.misc_feature_id", "misc_set.misc_set_id", "object_xref.object_xref_id", 
               "operon.operon_id", "peptide_archive.peptide_archive_id", "prediction_exon.prediction_exon_id",
               "prediction_transcript.prediction_transcript_id", "protein_align_feature.protein_align_feature_id", 
               "protein_feature.protein_feature_id", "repeat_consensus.repeat_consensus_id", 
               "repeat_feature.repeat_feature_id", "seq_region.seq_region_id", "seq_region_synonym.seq_region_synonym_id", 
               "simple_feature.simple_feature_id", "transcript.transcript_id", "translation.translation_id",
               "unmapped_object.unmapped_object_id", "unmapped_reason.unmapped_reason_id", "xref.xref_id");