package Input::HealthChecks;

use strict;
use warnings;


#Add healthchecks to this file to add them to the automatic change detection system.

our %healthchecks = (
    CoreForeignKeys => {
        hc_type => 1,
        tables => ['alt_allele', 'analysis', 'analysis_description', 'assembly', 'assembly_execution',
                   'associated_xref', 'attrib_type', 'coord_system', 'data_file', 'density_feature',
                   'density_type', 'dependent_xref', 'ditag', 'ditag_feature', 'dna', 'dna_align_feature',
                   'exon', 'exon_transcript', 'external_db', 'external_synonym', 'gene','gene_archive',
                   'gene_attrib', 'identity_xref', 'intron_supporting_evidence', 'map', 'mapping_session',
                   'marker', 'marker_feature', 'marker_map_location', 'marker_synonym', 'misc_attrib',
                   'misc_feature', 'misc_feature_misc_set', 'misc_set', 'object_xref', 'ontology_xref',
                   'operon', 'operon_transcript', 'peptide_archive', 'prediction_exon', 'prediction_transcript', 
                   'protein_align_feature', 'protein_feature', 'seq_region', 'seq_region_attrib', 
                   'simple_feature', 'stable_id_event', 'supporting_feature', 'transcript', 'transcript_attrib',
                   'transcript_intron_supporting_evidence', 'transcript_supporting_feature', 'translation',
                   'translation_attrib', 'unmapped_object', 'unmapped_reason', 'xref'],
        db_type => 'generic',
    },
    AssemblyMapping => {
        hc_type => 2,
        tables => ['coord_system', 'meta'],
        db_type => 'core',
    },
    LRG => {
        hc_type => 2,
        tables => ['coord_system', 'gene', 'seq_region', 'transcript'],
        db_type => 'core',
    },
    ProjectedXrefs => {
        hc_type => 2,
        tables => ['external_db', 'gene', 'xref'],
        db_type => 'core',
    },
    SeqRegionCoordSystem => {
        hc_type => 2,
        tables => ['coord_system', 'seq_region'],
        db_type => 'generic',
    },
    SequenceLevel => {
        hc_type => 2,
        tables => ['coord_system', 'dna', 'seq_region'],
        db_type => 'core',
    },
    XrefTypes => {
        hc_type => 2,
        tables => ['external_db', 'object_xref', 'transcript', 'xref'],
        db_type => 'core',
    },
    AutoIncrement => {
        hc_type => 3,
        tables => ['alt_allele', 'analysis', 'assembly_exception', 'attrib_type', 'coord_system', 'data_file',
                   'density_feature', 'ditag', 'ditag_feature', 'dna_align_feature', 'exon', 'external_db',
                   'gene', 'intron_supporting_evidence', 'karyotype', 'map', 'mapping_session', 'marker',
                   'marker_feature', 'marker_synonym', 'meta', 'misc_feature', 'misc_set', 'object_xref',
                   'operon', 'peptide_archive', 'prediction_exon', 'prediction_transcript', 'protein_align_feature',
                   'protein_feature', 'repeat_consensus', 'repeat_feature', 'seq_region', 'seq_region_synonym',
                   'simple_feature', 'transcript', 'translation', 'unmapped_object', 'unmapped_reason', 'xref'],
        db_type => 'generic',
    },
    Meta => {
        hc_type => 3,
        tables => ['meta'],
        db_type => 'generic',
    },
    AssemblyNameLength => {
        hc_type => 4,
        tables => ['meta'],
        db_type => 'core',
    },
    DataFiles => {
        hc_type => 4,
        tables => ['data_file'],
        db_type => 'rnaseq',
    },
    CoordSystemAcrossSpecies => {
        hc_type => 5,
        tables => ['coord_system'],
        db_type => 'generic',
    },
 );