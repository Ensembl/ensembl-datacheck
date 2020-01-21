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

package Bio::EnsEMBL::DataCheck::Checks::CheckPairAlignerUniqueMethod;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckPairAlignerUniqueMethod',
  DESCRIPTION    => 'Ensure that there is only one method for pairwise alignment per species_set',
  GROUPS         => ['compara', 'compara_pairwise_alignments'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['method_link', 'method_link_species_set']
};

sub tests {
  my ($self) = @_;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my @methods = qw( LASTZ_NET BLASTZ_NET TRANSLATED_BLAT_NET );
  my $db_name = $self->dba->dbc->dbname;
  my %species_sets;

  foreach my $method ( @methods ) {
    my $mlsses = $mlss_adap->fetch_all_by_method_link_type($method);
    foreach my $mlss ( @$mlsses ){
      my $mlss_id = $mlss->dbID;
      my $mlss_name = $mlss->name;
      my $ss_name = $mlss->species_set->name;
      my $ss_id = $mlss->species_set->dbID;
      $species_sets{"$ss_id ($ss_name)"}++;
    }
  }
  foreach my $species_set ( sort keys %species_sets ) {
    my $desc = "species_set $species_set has only one pairwise alignment method";
    is( $species_sets{$species_set}, 1, $desc );
  }

}

1;

