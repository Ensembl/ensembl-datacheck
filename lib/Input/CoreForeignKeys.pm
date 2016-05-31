=head1 NAME

  Input::CoreForeignKeys - contains foreign key relation information for the simplification and clarification
  of the CoreForeignKey investigation.
  
=head1 SYNOPSIS

  use Input::CoreForeignKeys;
  my %tables_hash = %$Input::CoreForeignKeys::core_foreign_keys;
  
=head2 DESCRIPTION

  Contains foreign-key pair information to be used by the CheckForOrphans module in the CoreForeignKey
  healthcheck. 
  
  To add a foreign-key dependency:
  The name of the referencing table is a key in the $core_foreign_keys hash. If the table is not used yet,
  create a new key. If it is used, create a hash reference inside it with a number as key (easiest way to 
  keep keys unique). col1 holds the name of the foreign key column in the referencing table. table2 is the
  name of the referenced table, and col2 is the name of the primary key column in that table. If col1 and col2
  have the same name, you can leave col2 out. Set both_ways to 1 if you want to check the dependency in both 
  directions, otherwise you can leave the both_ways variable out. If you have a constraint, pass it as a 
  string to constraint. Otherwise you can leave the constraint variable out.
  
=cut

package Input::CoreForeignKeys;

use strict;
use warnings;


our $core_foreign_keys = {
    alt_allele => {
        1 => {
            col1 => 'gene_id',
            table2 => 'gene',
        },
    },
    analysis_description => {
        1 => {
            col1 => 'analysis_id',
            table2 => 'analysis',
        },
    },    
    assembly => {
        1 => {
            col1 => 'asm_seq_region_id',
            table2 => 'seq_region',
            col2 => 'seq_region_id',
        },
        2 => {
            col1 => 'cmp_seq_region_id',
            table2 => 'seq_region',
            col2 => 'seq_region_id',
        },
    },
    assembly_exception => {
        1 => {
            col1 => 'seq_region_id',
            table2 => 'seq_region',
        },
        2 => {
            col1 => 'exc_seq_region_id',
            table2 => 'seq_region',
            col2 => 'seq_region_id',
        },
    },
    associated_xref => {
        1 => {
            col1 => 'object_xref_id',
            table2 => 'object_xref',
        },
        2 => {
            col1 => 'xref_id',
            table2 => 'xref',
        },
        3 => {
            col1 => 'source_xref_id',
            table2 => 'xref',
            col2 => 'xref_id',
        },
    },
    density_feature => {
        1 => {
            col1 => 'density_type_id',
            table2 => 'density_type',
        },
    },
    dependent_xref => {
        1 => {
            col1 => 'object_xref_id',
            table2 => 'object_xref',
        },
        2 => {
            col1 => 'master_xref_id',
            table2 => 'object_xref',
            col2 => 'xref_id',
        },
        3 => {
            col1 => 'dependent_xref_id',
            table2 => 'xref',
            col2 => 'xref_id',
        },
    },
    dna => {
        1 => {
            col1 => 'seq_region_id',
            table2 => 'seq_region',
         },         
     },
    exon => {
        1 => {
            col1 => 'exon_id',
            table2 => 'exon_transcript',
            both_ways => 1,
        },
    },
    external_synonym => {
        1 => {
            col1 => 'xref_id',
            table2 => 'xref',
        },
    },
    gene => {
        1 => {
            col1 => 'gene_id',
            table2 => 'transcript',
            both_ways => 1,
        },
    },
    gene_archive => {
        1 => {
            col1 => 'peptide_archive_id',
            table2 => 'peptide_archive',
            constraint => "gene_archive.peptide_archive_id != 0",
        },
        2 => {
            col1 => 'mapping_session_id',
            table2 => 'mapping_session',
        },
    },
    gene_attrib => {
        1 => {
            col1 => 'attrib_type_id',
            table2 => 'attrib_type',
        },
    },
    identity_xref => {
        1 => {
            col1 => 'object_xref_id',
            table2 => 'object_xref',
        },
    },
    marker => {
        1 => {
            col1 => 'display_marker_synonym_id',
            table2 => 'marker_synonym',
            col2 => 'marker_synonym_id',
        },
    },
    marker_feature => {
        1 => {
            col1 => 'marker_id',
            table2 => 'marker',
        },
    },
    marker_map_location => {
        1 => {
            col1 => 'map_id',
            table2 => 'map',
        },
        2 => {
            col1 => 'marker_id',
            table2 => 'marker',
        },
        3 => {
            col1 => 'marker_synonym_id',
            table2 => 'marker_synonym',
        },
    },
    marker_synonym => {
        1 => {
            col1 => 'marker_id',
            table2 => 'marker',
        },
    },
    misc_attrib => {
        1 => {
            col1 => 'attrib_type_id',
            table2 => 'attrib_type',
        },
    },
    misc_feature_misc_set => {
        1 => {
            col1 => 'misc_feature_id',
            table2 => 'misc_feature',
        },
        2 => {
            col1 => 'misc_set_id',
            table2 => 'misc_set',
        },
    },
    object_xref => {
        1 => {
            col1 => 'xref_id',
            table2 => 'xref',
        },
    },
    ontology_xref => {
        1 => {
            col1 => 'object_xref_id',
            table2 => 'object_xref',
        },
    },
    peptide_archive => {
        1 => {
            col1 => 'peptide_archive_id',
            table2 => 'gene_archive',
        },
    },
    prediction_exon => {
        1 => {
            col1 => 'prediction_transcript_id',
            table2 => 'prediction_transcript',
        },
    },
    protein_feature  => {
        1 => {
            col1 => 'translation_id',
            table2 => 'translation',
        },
    },
    seq_region => {
        1 => {
            col1 => 'coord_system_id',
            table2 => 'coord_system',
        },
        2 => {
            col1 => 'seq_region_id',
            table2 => 'dna',
            constraint => "coord_system_id = (SELECT coord_system_id FROM coord_system WHERE attrib LIKE '%sequence_level%')",
        },
    },
    seq_region_attrib => {
        1 => {
            col1 => 'seq_region_id',
            table2 => 'seq_region',
        },
        2 => {
            col1 => 'attrib_type_id',
            table2 => 'attrib_type',
        },
    },
    stable_id_event => {
        1 => {
            col1 => 'mapping_session_id',
            table2 => 'mapping_session',
        },
    },
    supporting_feature => {
        1 => {
            col1 => 'exon_id',
            table2 => 'exon',
        },
        2 => {
            col1 => 'feature_id',
            table2 => 'dna_align_feature',
            col2 => 'dna_align_feature_id',
            constraint => "supporting_feature.feature_type = 'dna_align_feature'",
        },
        3 => {
            col1 => 'feature_id',
            table2 => 'protein_align_feature',
            col2 => 'protein_align_feature_id',
            constraint => "supporting_feature.feature_type = 'protein_align_feature'",
        },
    },
    transcript => {
        1 => {
            col1 => 'transcript_id',
            table2 => 'exon_transcript',
            both_ways => 1,
        },
    },
    transcript_attrib => {
        1 => {
            col1 => 'transcript_id',
            table2 => 'transcript',
        },
        2 => {
            col1 => 'attrib_type_id',
            table2 => 'attrib_type',
        },
    },
    transcript_supporting_feature => {
        1 => {
            col1 => 'feature_id',
            table2 => 'dna_align_feature',
            col2 => 'dna_align_feature_id',
            constraint => "transcript_supporting_feature.feature_type = 'dna_align_feature'",
        },
        2 => {
            col1 => 'feature_id',
            table2 => 'protein_align_feature',
            col2 => 'protein_align_feature_id',
            constaint => "transcript_supporting_feature.feature_type = 'protein_align_feature",
        },
    },
    translation => {
        1 => {
            col1 => 'transcript_id',
            table2 => 'transcript',
        },
        2 => {
            col1 => 'end_exon_id',
            table2 => 'exon',
            col2 => 'exon_id',
        },
        3 => {
            col1 => 'start_exon_id',
            table2 => 'exon',
            col2 => 'exon_id',
        },
    },
    translation_attrib => {
        1 => {
            col1 => 'translation_id',
            table2 => 'translation',
        },
        2 => {
            col1 => 'attrib_type_id',
            table2 => 'attrib_type',
        },
    },
    unmapped_object => {
        1 => {
            col1 => 'unmapped_reason_id',
            table2 => 'unmapped_reason',
        },
        2 => {
            col1 => 'analysis_id',
            table2 => 'analysis',
        },
        3 => {
            col1 => 'external_db_id',
            table2 => 'external_db',
        },
    },
    xref => {
        1 => {
            col1 => 'external_db_id',
            table2 => 'external_db',
        },
    },
};
    