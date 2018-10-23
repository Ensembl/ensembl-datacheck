=head1 LICENSE

Copyright [2018] EMBL-European Bioinformatics Institute

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
  DESCRIPTION => 'Check for incorrect foreign key relationships',
  DB_TYPES    => ['compara', 'core', 'funcgen', 'otherfeatures', 'variation'],
  PER_DB      => 1,
};

sub tests {
  my ($self) = @_;

  my $fk_sql_file = $self->fk_sql_file();

  foreach my $line ( path($fk_sql_file)->lines ) {
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

  if ($self->dba->group =~ /(core|otherfeatures)/) {
    $self->core_fk();
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
  # in a "foreign_keys.sql" file..',

  # Cases in which we want to check for the reverse direction of the FK constraint
  fk($self->dba, 'exon',            'exon_id',            'exon_transcript');
  fk($self->dba, 'transcript',      'transcript_id',      'exon_transcript');
  fk($self->dba, 'gene',            'gene_id',            'transcript');
  fk($self->dba, 'mapping_session', 'mapping_session_id', 'stable_id_event');

  # Cases in which we need to restrict to a subset of rows, using a constraint
  fk($self->dba, 'object_xref', 'ensembl_id', 'gene',        'gene_id',        'ensembl_object_type = "Gene"');
  fk($self->dba, 'object_xref', 'ensembl_id', 'transcript',  'transcript_id',  'ensembl_object_type = "Transcript"');
  fk($self->dba, 'object_xref', 'ensembl_id', 'translation', 'translation_id', 'ensembl_object_type = "Translation"');

  fk($self->dba, 'supporting_feature',            'feature_id', 'dna_align_feature',     'dna_align_feature_id',     'feature_type = "dna_align_feature"');
  fk($self->dba, 'supporting_feature',            'feature_id', 'protein_align_feature', 'protein_align_feature_id', 'feature_type = "protein_align_feature"');
  fk($self->dba, 'transcript_supporting_feature', 'feature_id', 'dna_align_feature',     'dna_align_feature_id',     'feature_type = "dna_align_feature"');
  fk($self->dba, 'transcript_supporting_feature', 'feature_id', 'protein_align_feature', 'protein_align_feature_id', 'feature_type = "protein_align_feature"');
}

1;
