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

package Bio::EnsEMBL::DataCheck::Checks::ProteinTranslation;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ProteinTranslation',
  DESCRIPTION => 'All protein-coding genes have a valid translation',
  GROUPS      => ['core', 'geneset'],
  DB_TYPES    => ['core'],
  TABLES      => ['assembly', 'dna', 'exon', 'exon_transcript', 'gene', 'seq_region', 'seq_region_attrib', 'transcript', 'transcript_attrib', 'translation', 'translation_attrib']
};

sub tests {
  my ($self) = @_;

  # We don't use the 'coding' biotype group, because that contains
  # plenty of things which are nominally coding, but do not have
  # a valid translation. So restrict to the protein_coding biotype.
  my $ta = $self->dba->get_adaptor('Transcript');
  my $transcripts = $ta->fetch_all_by_biotype(['protein_coding']); 

  my @missing_translation = ();
  my @zero_length = ();
  my @internal_stop = ();

  for my $transcript (@$transcripts) {
    my $seq_obj = $transcript->translate();
    if (defined $seq_obj) {
      my $aa_seq = $seq_obj->seq();

      if (length($aa_seq) == 0) {
        my $msg = $transcript->stable_id." has zero-length translation";
        push @zero_length, $msg;
      }

      if ($aa_seq =~ /^X+$/ || $aa_seq =~ /\*/) {
        my $msg = $transcript->stable_id." has invalid translation: $aa_seq";
        push @internal_stop, $msg;
      }
    } else {
      my $msg = $transcript->stable_id." has no translation";
      push @missing_translation, $msg;
    }
  }

  my $desc_1 = "Protein-coding genes have translations";
  is(scalar(@missing_translation), 0, $desc_1) ||
    diag(join("\n", @missing_translation));

  my $desc_2 = "Amino acid sequences have non-zero length";
  is(scalar(@zero_length), 0, $desc_2) ||
    diag(join("\n", @zero_length));

  my $desc_3 = "Protein-coding genes have no internal stop codons";
  is(scalar(@internal_stop), 0, $desc_3) ||
    diag(join("\n", @internal_stop));
}

1;
