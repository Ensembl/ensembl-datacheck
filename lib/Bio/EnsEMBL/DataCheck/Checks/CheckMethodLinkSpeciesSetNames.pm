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

package Bio::EnsEMBL::DataCheck::Checks::CheckMethodLinkSpeciesSetNames;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckMethodLinkSpeciesSetNames',
  DESCRIPTION    => 'Check for consistency of names in method_link_species_set (and species_set_header)',
  GROUPS         => ['compara'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['genome_db', 'method_link_species_set', 'species_set', 'species_set_header']
};

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my $mlss = $mlss_adap->fetch_all;

  foreach my $mlss ( @$mlss ) {
    # The convention only applies to MLSSs that have been released and are current
    next if (!$mlss->first_release || $mlss->last_release);
    my $mlss_name = $mlss->name;
    my $mlss_id = $mlss->dbID;
    my $species_set = $mlss->species_set;
    my $species_set_name = $species_set->name;
    my $species_set_id = $species_set->dbID;
    my $gdbs = $species_set->genome_dbs;
    my $gdb_count = scalar( @$gdbs );

    if ( $mlss_name =~ /^([a-zA-Z\-\.]+) / ) {
      my $mlss_p1 = $1;
      my $desc_2 = "species_set $species_set_id for mlss $mlss_name ($mlss_id) starts with the species_set name $species_set_name";
      if ( $species_set_name =~ /collection/ ) {
        is( $species_set_name, "collection-$mlss_p1", $desc_2 );
      }
      else {
        is( $species_set_name, $mlss_p1, $desc_2 );
      }
    }
    if ( $gdb_count >= 1 && $gdb_count <=2 ) {
      my @species_count = split /-/, $species_set_name;
      my $desc_3 = "For $mlss_name ($mlss_id) the species_set $species_set_name ($species_set_id) is appropriately named with the correct number of genomes";
      is( $gdb_count, scalar( @species_count ), $desc_3 );
    }
  }
}

1;
