=head1 LICENSE

Copyright [2018-2019] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the 'License');
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an 'AS IS' BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Bio::EnsEMBL::DataCheck::Checks::ForeignKeys;

use warnings;
use strict;
use feature 'say';

use Moose;
use Path::Tiny;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/repo_location/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ForeignKeys',
  DESCRIPTION => 'Foreign key relationships are not violated',
  GROUPS      => ['compara', 'core', 'corelike', 'funcgen', 'schema', 'variation'],
  DB_TYPES    => ['cdna', 'compara', 'core', 'funcgen', 'otherfeatures', 'rnaseq', 'variation'],
  PER_DB      => 1,
};

sub tests {
  my ($self) = @_;

  my $fk_sql_file = $self->fk_sql_file();

  foreach my $line ( path($fk_sql_file)->lines ) {
    next if $line =~ /^\-\-/;
    next unless $line =~ /FOREIGN KEY/;

    my ($table1, $col1, $table2, $col2) = $line =~
      /ALTER\s+TABLE\s+(\S+)\s+ADD\s+FOREIGN\s+KEY\s+\((\S+)\)\s+REFERENCES\s+(\S+)\s*\((\S+)\)/i;

    if (defined $table1 && defined $col1 && defined $table2 && defined $col2) {
      # In theory, need exceptions for gene_archive.peptide_archive_id and object_xref.analysis_id
      # which can be zero. But really, they should be null. And if they're not supposed
      # to be null, then they shouldn't be zero either.
       fk($self->dba, $table1, $col1, $table2, $col2);
    } else {
      die "Failed to parse foreign key relationship from $line";
    }
  }

  if ($self->dba->group =~ /(cdna|core|otherfeatures|rnaseq)/) {
    $self->core_fk();
  } elsif ($self->dba->group eq 'funcgen') {
    $self->funcgen_fk();
  } elsif ($self->dba->group eq 'variation') {
    $self->variation_fk();
  }
}

sub fk_sql_file {
  my ($self) = @_;

  # Don't need checking here, the DB_TYPES ensure we won't get
  # a $dba from a group that we can't handle, and the repo_location
  # method will die if the repo path isn't visible to Perl.
  my $repo_location = repo_location($self->dba->group);
  my $fk_sql_file   = "$repo_location/sql/foreign_keys.sql";

  if (! -e $fk_sql_file) {
    die "Foreign keys file does not exist: $fk_sql_file";
  }

  return $fk_sql_file;
}

sub core_fk {
  my ($self) = @_;
  # Check for incorrect foreign key relationships that are not defined
  # in a "foreign_keys.sql" file.

  # Cases in which we want to check for the reverse direction of the FK constraint
  fk($self->dba, 'exon',                  'exon_id',                  'exon_transcript');
  fk($self->dba, 'transcript',            'transcript_id',            'exon_transcript');
  fk($self->dba, 'gene',                  'gene_id',                  'transcript');
  fk($self->dba, 'prediction_transcript', 'prediction_transcript_id', 'prediction_exon');
  fk($self->dba, 'mapping_session',       'mapping_session_id',       'stable_id_event');
  
  # I think this one should be enforced, but need to investigate
  # downsides, and give people some warning, since a lot of dbs would fail...
  #fk($self->dba, 'analysis', 'analysis_id', 'analysis_description');

  # Cases in which we need to restrict to a subset of rows, using a constraint
  fk($self->dba, 'object_xref', 'ensembl_id', 'gene',        'gene_id',        'ensembl_object_type = "Gene"');
  fk($self->dba, 'object_xref', 'ensembl_id', 'transcript',  'transcript_id',  'ensembl_object_type = "Transcript"');
  fk($self->dba, 'object_xref', 'ensembl_id', 'translation', 'translation_id', 'ensembl_object_type = "Translation"');

  fk($self->dba, 'supporting_feature',            'feature_id', 'dna_align_feature',     'dna_align_feature_id',     'feature_type = "dna_align_feature"');
  fk($self->dba, 'supporting_feature',            'feature_id', 'protein_align_feature', 'protein_align_feature_id', 'feature_type = "protein_align_feature"');
  fk($self->dba, 'transcript_supporting_feature', 'feature_id', 'dna_align_feature',     'dna_align_feature_id',     'feature_type = "dna_align_feature"');
  fk($self->dba, 'transcript_supporting_feature', 'feature_id', 'protein_align_feature', 'protein_align_feature_id', 'feature_type = "protein_align_feature"');
}

sub funcgen_fk {
  my ($self) = @_;
  # Check for incorrect foreign key relationships that are not defined
  # in a "foreign_keys.sql" file.

  # Cases in which we want to check for the reverse direction of the FK constraint
  fk($self->dba, 'read_file', 'read_file_id', 'alignment_read_file');

  # Cases in which we need to restrict to a subset of rows, using a constraint
  fk($self->dba, 'associated_feature_type', 'table_id', 'external_feature',   'external_feature_id',   'table_name = "external_feature"');
  fk($self->dba, 'associated_feature_type', 'table_id', 'regulatory_feature', 'regulatory_feature_id', 'table_name = "regulatory_feature"');

  fk($self->dba, 'data_file', 'table_id', 'external_feature_file', 'external_feature_file_id', 'table_name = "external_feature_file"');
  fk($self->dba, 'data_file', 'table_id', 'segmentation_file',     'segmentation_file_id',     'table_name = "segmentation_file"');

  fk($self->dba, 'object_xref', 'ensembl_id', 'epigenome',            'epigenome_id',            'ensembl_object_type = "Epigenome"');
  fk($self->dba, 'object_xref', 'ensembl_id', 'experiment',           'experiment_id',           'ensembl_object_type = "Experiment"');
  fk($self->dba, 'object_xref', 'ensembl_id', 'regulatory_feature',   'regulatory_feature_id',   'ensembl_object_type = "RegulatoryFeature"');
  fk($self->dba, 'object_xref', 'ensembl_id', 'external_feature',     'external_feature_id',     'ensembl_object_type = "ExternalFeature"');
  fk($self->dba, 'object_xref', 'ensembl_id', 'feature_type',         'feature_type_id',         'ensembl_object_type = "FeatureType"');
  fk($self->dba, 'object_xref', 'ensembl_id', 'mirna_target_feature', 'mirna_target_feature_id', 'ensembl_object_type = "MirnaTargetFeature"');
  fk($self->dba, 'object_xref', 'ensembl_id', 'probe_set',            'probe_set_id',            'ensembl_object_type = "ProbeSet"');
  fk($self->dba, 'object_xref', 'ensembl_id', 'probe',                'probe_id',                'ensembl_object_type = "Probe"');
  fk($self->dba, 'object_xref', 'ensembl_id', 'probe_feature',        'probe_feature_id',        'ensembl_object_type = "ProbeFeature"');
}

sub variation_fk {
  my ($self) = @_;
  # Check for incorrect foreign key relationships that are not defined
  # in a "foreign_keys.sql" file.

  # Cases in which we want to check for the reverse direction of the FK constraint
  fk($self->dba, 'phenotype', 'phenotype_id', 'phenotype_feature');

  # "Temporary" table is not included in the "foreign_keys.sql" file
  fk($self->dba, 'tmp_sample_genotype_single_bp', 'sample_id',    'sample');
  fk($self->dba, 'tmp_sample_genotype_single_bp', 'variation_id', 'variation');

  # Cases in which we need to restrict to a subset of rows, using a constraint
  fk($self->dba, 'phenotype_feature', 'object_id', 'structural_variation', 'variation_name', 'type IN ("StructuralVariation", "SupportingStructuralVariation")');
  fk($self->dba, 'phenotype_feature', 'object_id', 'variation',            'name',           'type = "Variation"');

  fk($self->dba, 'compressed_genotype_region', 'seq_region_id', 'variation_feature', 'seq_region_id', 't1.seq_region_start = t2.seq_region_start');
}

1;
