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

package Bio::EnsEMBL::DataCheck::Checks::ProteinTranslation;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ProteinTranslation',
  DESCRIPTION => 'Check that every protein-coding gene has a valid translation',
  GROUPS      => ['core'],
  DB_TYPES    => ['core'],
  TABLES      => ['assembly', 'dna', 'exon', 'exon_transcript', 'gene', 'seq_region', 'seq_region_attrib', 'transcript', 'transcript_attrib', 'translation', 'translation_attrib']
};

sub tests {
  my ($self) = @_;

  my $ba = $self->dba->get_adaptor('Biotype');
  my $biotype_objs = $ba->fetch_all_by_group_object_db_type(
    'coding', 'transcript', $self->dba->group
  );
  my @biotypes = map { $_->name } @$biotype_objs;

  my $ta = $self->dba->get_adaptor('Transcript');
  my $transcripts = $ta->fetch_all_by_biotype(\@biotypes); 

  my $invalid_translations = 0;

  for my $transcript (@$transcripts) {
    my $seq_obj = $transcript->translate();
    if (defined $seq_obj) {
      my $aa_seq = $seq_obj->seq();

      if ($aa_seq =~ /^X+$/ || $aa_seq =~ /\*/) {
        $invalid_translations++;
        diag($transcript->stable_id." has invalid translation: $aa_seq");
      }
    } else {
      $invalid_translations++;
      diag($transcript->stable_id." has no translation");
    }
  }

  my $desc = "Protein-coding genes have valid translations";
  is($invalid_translations, 0, $desc);
}

1;
