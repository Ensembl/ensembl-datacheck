=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::MultipleGenomicAlignBlockIds;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'MultipleGenomicAlignBlockIds',
  DESCRIPTION    => 'Check that every genomic_align_block_id has more than one genomic_align_id',
  GROUPS         => ['compara', 'compara_genome_alignments'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['genomic_align', 'method_link', 'method_link_species_set']
};

sub skip_tests {
    my ($self) = @_;
    my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
    my @methods = qw (CACTUS_DB PECAN CACTUS_HAL LASTZ_NET LASTZ_PATCH EPO_EXTENDED);
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
  my $dba = $self->dba;
  my $dbc = $dba->dbc;
  my $mlss_adap = $dba->get_MethodLinkSpeciesSetAdaptor;
  my @mlss_types = qw (CACTUS_DB PECAN CACTUS_HAL LASTZ_NET LASTZ_PATCH EPO_EXTENDED);
  my @mlsses;
  
  # The tests are excluded from the EPO methods because these have ancestral sequences in
  # different genomic_align_block_ids.
  
  foreach my $mlss_type ( @mlss_types ) {
    my $mlss = $mlss_adap->fetch_all_by_method_link_type($mlss_type);
    push @mlsses, @$mlss;
  }
  
  foreach my $mlss ( @mlsses ) {
    my $mlss_id = $mlss->dbID;
    my $mlss_name = $mlss->name;
    my $constraint = "method_link_species_set_id = $mlss_id";
    
    my $desc = "For $mlss_name ($mlss_id) every genomic_align_block_id has more than one genomic_align_id";
    is_one_to_many($dbc, "genomic_align", "genomic_align_block_id", $desc, $constraint);
  }
}

1;

