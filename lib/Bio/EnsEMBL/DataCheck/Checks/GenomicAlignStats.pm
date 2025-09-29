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

package Bio::EnsEMBL::DataCheck::Checks::GenomicAlignStats;

use warnings;
use strict;

use Moose;
use Test::More;

use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'GenomicAlignStats',
  DESCRIPTION    => 'Check consistency of genomic alignment stats',
  GROUPS         => ['compara', 'compara_genome_alignments'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['genomic_align_block', 'method_link', 'method_link_species_set', 'method_link_species_set_tag']
};

sub skip_tests {
    my ($self) = @_;
    my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
    my @method_types = qw (CACTUS_DB EPO EPO_EXTENDED LASTZ_NET LASTZ_PATCH PECAN POLYPLOID);
    my $db_name = $self->dba->dbc->dbname;

    my @mlsses;
    foreach my $method_type ( @method_types ) {
      my $mlsses_of_type = $mlss_adap->fetch_all_by_method_link_type($method_type);
      push @mlsses, @{$mlsses_of_type};
    }

    if ( scalar(@mlsses) == 0 ) {
      return( 1, "There are no genomic alignments in $db_name" );
    }
}

sub tests {
  my ($self) = @_;
  my $dba = $self->dba;
  my $helper = $dba->dbc->sql_helper;
  my $mlss_adap = $dba->get_MethodLinkSpeciesSetAdaptor;
  my @method_types = qw (CACTUS_DB EPO EPO_EXTENDED LASTZ_NET LASTZ_PATCH PECAN POLYPLOID);

  my %mlsses_by_id;
  foreach my $method_type ( @method_types ) {
    my $mlsses_of_type = $mlss_adap->fetch_all_by_method_link_type($method_type);
    foreach my $mlss (@{$mlsses_of_type}) {
      $mlsses_by_id{$mlss->dbID} = $mlss;
    }
  }

  my $block_count_tag_sql = q/
    SELECT value
    FROM method_link_species_set_tag
    WHERE method_link_species_set_id = ?
    AND tag = 'num_blocks'
  /;

  my %exp_block_counts;
  foreach my $mlss_id ( sort keys %mlsses_by_id ) {
    my $results = $helper->execute_simple( -SQL => $block_count_tag_sql, -PARAMS => [$mlss_id] );

    if (scalar(@{$results}) == 1) {
      my $block_count_tag = $results->[0];
      my $mlss = $mlsses_by_id{$mlss_id};
      my $exp_block_count = $mlss->method->type eq 'EPO'
                          ? 2 * $block_count_tag
                          : $block_count_tag
                          ;

      $exp_block_counts{$mlss_id} = $exp_block_count;
    }
  }

  my $gab_count_sql = q/
    SELECT COUNT(*)
    FROM genomic_align_block
    WHERE method_link_species_set_id = ?
  /;

  foreach my $mlss_id ( sort keys %exp_block_counts ) {
    my $results = $helper->execute_simple( -SQL => $gab_count_sql, -PARAMS => [$mlss_id] );
    my $obs_block_count = $results->[0];
    my $exp_block_count = $exp_block_counts{$mlss_id};
    my $mlss_name = $mlsses_by_id{$mlss_id}->name;
    is($obs_block_count, $exp_block_count, "$mlss_name (mlss_id:$mlss_id) block count consistency");
  }

}

1;
