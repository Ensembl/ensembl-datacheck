=head1 LICENSE

Copyright [2018-2025] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::MLSSTagPairwiseAlignment;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::Compara;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MLSSTagPairwiseAlignment',
  DESCRIPTION => 'Pairwise alignments have appropriate tags',
  GROUPS      => ['compara', 'compara_genome_alignments'],
  DB_TYPES    => ['compara'],
  TABLES      => ['method_link', 'method_link_species_set', 'method_link_species_set_tag']
};

sub skip_tests {
  my ($self) = @_;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my @methods = qw( LASTZ_NET BLASTZ_NET TRANSLATED_BLAT_NET );
  my $db_name = $self->dba->dbc->dbname;
  
  my @mlsses;
  foreach my $method ( @methods ) {
    my $mlss = $mlss_adap->fetch_all_by_method_link_type($method);
    push @mlsses, @$mlss;
  }
  
  if ( scalar(@mlsses) == 0 ) {
    return( 1, "There are no multiple alignments in $db_name" );
  }
}

sub tests {
  my ($self) = @_;

  my $tags = [
    'non_ref_coding_exon_length',
    'non_ref_genome_coverage',
    'non_ref_genome_length',
    'non_ref_insertions',
    'non_ref_matches',
    'non_ref_mis_matches',
    'non_ref_uncovered',
    'ref_coding_exon_length',
    'ref_genome_coverage',
    'ref_genome_length',
    'ref_insertions',
    'ref_matches',
    'ref_mis_matches',
    'ref_uncovered'
  ];

  has_tags($self->dba, 'BLASTZ_NET', $tags);
  has_tags($self->dba, 'LASTZ_NET', $tags);
  has_tags($self->dba, 'TRANSLATED_BLAT_NET', $tags);

  cmp_tag($self->dba, 'BLASTZ_NET', 'non_ref_coding_exon_length', '>', 0);
  cmp_tag($self->dba, 'LASTZ_NET', 'non_ref_coding_exon_length', '>', 0);
  cmp_tag($self->dba, 'TRANSLATED_BLAT_NET', 'non_ref_coding_exon_length', '>', 0);


  my @mlsses;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  foreach my $method_type ('LASTZ_NET', 'BLASTZ_NET', 'TRANSLATED_BLAT_NET') {
    my $mlsses_of_type = $mlss_adap->fetch_all_by_method_link_type($method_type);
    push @mlsses, @{$mlsses_of_type};
  }

  foreach my $mlss (@mlsses) {

    if ($mlss->has_tag('reference_species') && $mlss->has_tag('non_reference_species')) {
      my $non_ref_sp_name = $mlss->get_value_for_tag('non_reference_species');
      my $ref_sp_name = $mlss->get_value_for_tag('reference_species');

      if ($mlss->species_set->size > 1) {

        my $desc_1 = sprintf(
          "alignment MLSS '%s' (mlss_id:%d) reference-species tag distinctness",
          $mlss->name,
          $mlss->dbID,
        );

        isnt($non_ref_sp_name, $ref_sp_name, $desc_1);

      } else {

        my $desc_2 = sprintf(
          "self-alignment MLSS '%s' (mlss_id:%d) reference-species tag identity",
          $mlss->name,
          $mlss->dbID,
        );

        is($non_ref_sp_name, $ref_sp_name, $desc_2);

      }
    }
  }
}

1;
