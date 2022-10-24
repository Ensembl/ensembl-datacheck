=head1 LICENSE

Copyright [2018-2022] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CheckGenomicAlignments;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::Utils::SqlHelper;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckGenomicAlignments',
  DESCRIPTION    => 'The expected number of genomic alignments have been merged',
  GROUPS         => ['compara', 'compara_genome_alignments'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['method_link_species_set', 'genomic_align', 'genomic_align_block']
};

sub skip_tests {
  my ($self) = @_;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;

  my @method_links = qw(LASTZ_NET LASTZ_PATCH EPO EPO_EXTENDED PECAN POLYPLOID TRANSLATED_BLAT_NET);
  my @mlsss;
  foreach my $method (@method_links) {
    my $mlss = $mlss_adap->fetch_all_by_method_link_type($method);
    push @mlsss, @$mlss;
  }

  my $db_name = $self->dba->dbc->dbname;

  if ( scalar(@mlsss) == 0 ) {
    return( 1, "There are no genomic alignment MLSS in $db_name" );
  }
}

sub tests {
  my ($self) = @_;
  my $dba    = $self->dba;
  my $helper = $dba->dbc->sql_helper;
  my @method_links = qw(LASTZ_NET LASTZ_PATCH EPO EPO_EXTENDED PECAN POLYPLOID TRANSLATED_BLAT_NET);

  my $expected_align_count;
  my @tables    = qw(genomic_align genomic_align_block);

  foreach my $table (@tables) {
    foreach my $method_link_type ( @method_links ) {

      my $mlsss = $self->dba->get_MethodLinkSpeciesSetAdaptor->fetch_all_by_method_link_type($method_link_type);
      # Only check from the method_links that have mlsss there are other datachecks to check if mlsss are correct
      next if scalar(@$mlsss) == 0;

      foreach my $mlss ( @$mlsss ) {

        my $mlss_id   = $mlss->dbID;
        my $mlss_name = $mlss->name;

        my $sql = qq/
          SELECT COUNT(*)
            FROM $table
          WHERE method_link_species_set_id = $mlss_id
        /;

        $expected_align_count += $helper->execute_single_result(-SQL => $sql) if $table eq "genomic_align";

        my $desc_1 = "The $table for $mlss_id ($mlss_name) has rows as expected";
        is_rows_nonzero($dba, $sql, $desc_1);
      }
    }
  }
    # Check that all the genomic_aligns correspond to a method_link_species_set that should have an alignment
    my $desc_2 = "All the genomic_align rows with corresponding method_link_species_sets are expected";
    my $row_count_sql = "SELECT COUNT(*) FROM genomic_align";
    is_rows($dba, $row_count_sql, $expected_align_count, $desc_2);
}

1;
