=head1 LICENSE

Copyright [2016] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 NAME

Bio::EnsEMBL::DataCheck::Utils::TableSets

=head1 SYNOPSIS

my $core_keys = get_core_foreign_keys();

=head1 DESCRIPTION

Package defining tables and keys used in healthchecks

=head1 METHODS

=cut

package Bio::EnsEMBL::DataCheck::Utils::TableSets;

use warnings;
use strict;

BEGIN {
  require Exporter;
  our $VERSION = 1.00;
  our @ISA     = qw(Exporter);
  our @EXPORT =
    qw(get_feature_tables get_object_xref_tables get_tables_with_analysis_id get_funcgen_feature_tables get_funcgen_tables_with_analysis_id get_core_foreign_keys);
}

my $feature_tables = [ 'assembly_exception',    'gene',
                       'exon',                  'dna_align_feature',
                       'protein_align_feature', 'repeat_feature',
                       'simple_feature',        'marker_feature',
                       'misc_feature',          'karyotype',
                       'transcript',            'density_feature',
                       'prediction_exon',       'prediction_transcript',
                       'operon',                'operon_transcript',
                       'ditag_feature' ];

my $tables_with_analysis_id = [
                              'gene',              'protein_feature',
                              'dna_align_feature', 'protein_align_feature',
                              'repeat_feature',    'prediction_transcript',
                              'simple_feature',    'marker_feature',
                              'density_type',      'object_xref',
                              'transcript',        'intron_supporting_evidence',
                              'operon',            'operon_transcript',
                              'unmapped_object',   'ditag_feature',
                              'data_file' ];

my $funcgen_feature_tables = [ 'probe_feature',      'annotated_feature',
                               'regulatory_feature', 'external_feature',
                               'motif_feature',      'mirna_target_feature',
                               'segmentation_feature' ];

my $funcgen_tables_with_analysis_id = [ 'probe_feature',   'object_xref',
                                        'unmapped_object', 'feature_set',
                                        'result_set' ];

my $object_xref_tables = [ 'gene',              'transcript',
                           'translation',       'operon',
                           'operon_transcript', 'marker' ];

my $core_foreign_keys = {
  alt_allele           => [ { col1 => 'gene_id',     table2 => 'gene', } ],
  analysis_description => [ { col1 => 'analysis_id', table2 => 'analysis' } ],
  assembly             => [ {
                  col1   => 'asm_seq_region_id',
                  table2 => 'seq_region',
                  col2   => 'seq_region_id' }, {
                  col1   => 'cmp_seq_region_id',
                  table2 => 'seq_region',
                  col2   => 'seq_region_id' } ],
  assembly_exception => [ { col1 => 'seq_region_id', table2 => 'seq_region', },
                          { col1   => 'exc_seq_region_id',
                            table2 => 'seq_region',
                            col2   => 'seq_region_id' } ],
  associated_xref => [
               { col1 => 'object_xref_id', table2 => 'object_xref' },
               { col1 => 'xref_id',        table2 => 'xref' },
               { col1 => 'source_xref_id', table2 => 'xref', col2 => 'xref_id' }
  ],
  density_feature =>
    [ { col1 => 'density_type_id', table2 => 'density_type' } ],
  dependent_xref => [
     { col1 => 'object_xref_id', table2 => 'object_xref' },
     { col1 => 'master_xref_id', table2 => 'object_xref', col2 => 'xref_id' },
     { col1 => 'dependent_xref_id', table2 => 'xref', col2 => 'xref_id' } ],
  dna => [ { col1 => 'seq_region_id', table2 => 'seq_region' } ],
  exon =>
    [ { col1 => 'exon_id', table2 => 'exon_transcript', both_ways => 1 } ],
  external_synonym => [ { col1 => 'xref_id', table2 => 'xref' } ],
  gene => [ { col1 => 'gene_id', table2 => 'transcript', both_ways => 1 } ],
  gene_archive => [ { col1       => 'peptide_archive_id',
                      table2     => 'peptide_archive',
                      constraint => "gene_archive.peptide_archive_id != 0" }, {
                      col1   => 'mapping_session_id',
                      table2 => 'mapping_session' } ],
  gene_attrib   => [ { col1 => 'attrib_type_id', table2 => 'attrib_type' } ],
  identity_xref => [ { col1 => 'object_xref_id', table2 => 'object_xref' } ],
  marker        => [ {
                col1   => 'display_marker_synonym_id',
                table2 => 'marker_synonym',
                col2   => 'marker_synonym_id' } ],
  marker_feature      => [ { col1 => 'marker_id', table2 => 'marker' } ],
  marker_map_location => [ { col1 => 'map_id',    table2 => 'map' },
                           { col1 => 'marker_id', table2 => 'marker' },
                           { col1   => 'marker_synonym_id',
                             table2 => 'marker_synonym' } ],
  marker_synonym => [ { col1 => 'marker_id',      table2 => 'marker' } ],
  misc_attrib    => [ { col1 => 'attrib_type_id', table2 => 'attrib_type' } ],
  misc_feature_misc_set => [ { col1   => 'misc_feature_id',
                               table2 => 'misc_feature' },
                             { col1 => 'misc_set_id', table2 => 'misc_set' } ],
  object_xref   => [ { col1 => 'xref_id',        table2 => 'xref' } ],
  ontology_xref => [ { col1 => 'object_xref_id', table2 => 'object_xref' } ],
  peptide_archive =>
    [ { col1 => 'peptide_archive_id', table2 => 'gene_archive' } ],
  prediction_exon => [
       { col1 => 'prediction_transcript_id', table2 => 'prediction_transcript' }
  ],
  protein_feature => [ { col1 => 'translation_id', table2 => 'translation' } ],
  seq_region      => [
    { col1 => 'coord_system_id', table2 => 'coord_system' },
    { col1   => 'seq_region_id',
      table2 => 'dna',
      constraint =>
"coord_system_id = (SELECT coord_system_id FROM coord_system WHERE attrib LIKE '%sequence_level%')",
    } ],
  seq_region_attrib => [ { col1 => 'seq_region_id',  table2 => 'seq_region' },
                         { col1 => 'attrib_type_id', table2 => 'attrib_type' }
  ],
  stable_id_event =>
    [ { col1 => 'mapping_session_id', table2 => 'mapping_session' } ],
  supporting_feature => [
     { col1 => 'exon_id', table2 => 'exon' },
     { col1       => 'feature_id',
       table2     => 'dna_align_feature',
       col2       => 'dna_align_feature_id',
       constraint => "supporting_feature.feature_type = 'dna_align_feature'" },
     { col1       => 'feature_id',
       table2     => 'protein_align_feature',
       col2       => 'protein_align_feature_id',
       constraint => "supporting_feature.feature_type = 'protein_align_feature'"
     } ],
  transcript => [
        { col1 => 'transcript_id', table2 => 'exon_transcript', both_ways => 1 }
  ],
  transcript_attrib => [ { col1 => 'transcript_id',  table2 => 'transcript' },
                         { col1 => 'attrib_type_id', table2 => 'attrib_type' }
  ],
  transcript_supporting_feature => [ {
         col1   => 'feature_id',
         table2 => 'dna_align_feature',
         col2   => 'dna_align_feature_id',
         constraint =>
           "transcript_supporting_feature.feature_type = 'dna_align_feature'" },
       { col1   => 'feature_id',
         table2 => 'protein_align_feature',
         col2   => 'protein_align_feature_id',
         constaint =>
           "transcript_supporting_feature.feature_type = 'protein_align_feature"
       } ],
  translation => [ { col1 => 'transcript_id', table2 => 'transcript' },
                   { col1   => 'end_exon_id',
                     table2 => 'exon',
                     col2   => 'exon_id' }, {
                     col1   => 'start_exon_id',
                     table2 => 'exon',
                     col2   => 'exon_id' } ],
  translation_attrib => [ { col1 => 'translation_id', table2 => 'translation' },
                          { col1 => 'attrib_type_id', table2 => 'attrib_type' }
  ],
  unmapped_object => [ { col1   => 'unmapped_reason_id',
                         table2 => 'unmapped_reason' },
                       { col1 => 'analysis_id',    table2 => 'analysis' },
                       { col1 => 'external_db_id', table2 => 'external_db' } ],
  xref => [ { col1 => 'external_db_id', table2 => 'external_db' } ] };

=head2 get_feature_tables

  Description: Get list of tables representing genomic features
  Returntype : arrayref of strings
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut
sub get_feature_tables {
  return $feature_tables;
}

=head2 get_object_xref_tables

  Description: Get list of tables referencing object_xref
  Returntype : arrayref of strings
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut
sub get_object_xref_tables {
  return $object_xref_tables;
}

=head2 get_tables_with_analysis_id

  Description: Get list of tables which reference analysis
  Returntype : arrayref of strings
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut
sub get_tables_with_analysis_id {
  return $tables_with_analysis_id;
}

=head2 get_funcgen_feature_tables

  Description: Get list of funcgen tables representing features
  Returntype : arrayref of strings
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut
sub get_funcgen_feature_tables {
  return $funcgen_feature_tables;
}

=head2 get_funcgen_tables_with_analysis_id

  Description: Get list of funcgen tables which reference analysis
  Returntype : arrayref of strings
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut
sub get_funcgen_tables_with_analysis_id {
  return $funcgen_tables_with_analysis_id;
}

=head2 get_core_foreign_keys

  Description: Get list of tables which reference analysis
  Returntype : hashref of tables where values are an arrayref of hashrefs 
               containing column details 
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut
sub get_core_foreign_keys {
  return $core_foreign_keys;
}
1;
