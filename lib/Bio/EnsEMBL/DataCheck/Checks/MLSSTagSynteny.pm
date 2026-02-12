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

package Bio::EnsEMBL::DataCheck::Checks::MLSSTagSynteny;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::Compara;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MLSSTagSynteny',
  DESCRIPTION => 'Syntenies have appropriate tags',
  GROUPS      => ['compara', 'compara_syntenies'],
  DB_TYPES    => ['compara'],
  TABLES      => ['method_link', 'method_link_species_set', 'method_link_species_set_tag']
};

sub skip_tests {
  my ($self) = @_;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my $mlss = $mlss_adap->fetch_all_by_method_link_type('SYNTENY');
  my $db_name = $self->dba->dbc->dbname;

  if ( scalar(@$mlss) == 0 ) {
    return( 1, "There are no SYNTENY MLSS in $db_name" );
  }
}

sub tests {
  my ($self) = @_;

  my $tags = [
    'num_blocks',
    'non_reference_species',
    'non_ref_coding_exon_length',
    'non_ref_covered',
    'non_ref_genome_coverage',
    'non_ref_genome_length',
    'non_ref_uncovered',
    'reference_species',
    'ref_coding_exon_length',
    'ref_covered',
    'ref_genome_coverage',
    'ref_genome_length',
    'ref_uncovered',
  ];

  has_tags($self->dba, 'SYNTENY', $tags);

  cmp_tag($self->dba, 'SYNTENY', 'non_ref_coding_exon_length', '>', 0);

  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;

  my $mlsses = $mlss_adap->fetch_all_by_method_link_type('SYNTENY');
  foreach my $mlss (@{$mlsses}) {

    if ($mlss->has_tag('reference_species') || $mlss->has_tag('non_reference_species')) {

      if ($mlss->has_tag('pairwise_mlss_id')) {
        my $pairwise_mlss_id = $mlss->get_value_for_tag('pairwise_mlss_id');

        my $pairwise_mlss = $mlss_adap->fetch_by_dbID($pairwise_mlss_id);

        my $desc_3 = sprintf("synteny MLSS '%s' (mlss_id:%d) pairwise_mlss_id referential integrity", $mlss->name, $mlss->dbID);
        isa_ok($pairwise_mlss, 'Bio::EnsEMBL::Compara::MethodLinkSpeciesSet', $desc_3);

        foreach my $tag ('reference_species', 'non_reference_species') {
          my $synteny_tag_value = $mlss->get_value_for_tag($tag);
          my $pairwise_tag_value = $pairwise_mlss->get_value_for_tag($tag);
          if (defined $synteny_tag_value && $pairwise_tag_value) {
            my $desc_4 = sprintf(
              "'%s' tag consistency between synteny MLSS '%s' (mlss_id:%d) and pairwise MLSS '%s' (mlss_id:%d)",
              $tag,
              $mlss->name,
              $mlss->dbID,
              $pairwise_mlss->name,
              $pairwise_mlss->dbID,
            );

            is($synteny_tag_value, $pairwise_tag_value, $desc_4);
          }
        }
      }

      if ($mlss->has_tag('reference_species') && $mlss->has_tag('non_reference_species')) {
        my $non_ref_sp_name = $mlss->get_value_for_tag('non_reference_species');
        my $ref_sp_name = $mlss->get_value_for_tag('reference_species');

        if ($mlss->species_set->size > 1) {

          my $desc_1 = sprintf(
            "synteny MLSS '%s' (mlss_id:%d) reference-species tag distinctness",
            $mlss->name,
            $mlss->dbID,
          );

          isnt($non_ref_sp_name, $ref_sp_name, $desc_1);

        } else {

          my $desc_2 = sprintf(
            "synteny MLSS '%s' (mlss_id:%d) reference-species tag identity",
            $mlss->name,
            $mlss->dbID,
          );

          is($non_ref_sp_name, $ref_sp_name, $desc_2);
        }
      }
    }
  }
}

1;
