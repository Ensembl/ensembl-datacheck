=head1 LICENSE

# Copyright [2018] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

=cut

package Bio::EnsEMBL::DataCheck::Checks::CoreForeignKeys;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'CoreForeignKeys',
  DESCRIPTION => 'Check for incorrect foreign key relationships that are not defined by a "foreign_keys.sql" file..',
  GROUPS      => ['handover'],
  DB_TYPES    => ['core', 'otherfeatures'],
  PER_DB      => 1,
};

sub tests {
  my ($self) = @_;

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
