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

package Bio::EnsEMBL::DataCheck::Checks::CheckSpeciesSetSizeByMethod;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckSpeciesSetSizeByMethod',
  DESCRIPTION    => 'Checks that the species-sets have the expected number of genomes',
  GROUPS         => ['compara', 'compara_pairwise_alignments', 'compara_protein_trees', 'compara_syntenies'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['method_link', 'method_link_species_set', 'species_set']
};

sub tests {
  my ($self) = @_;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;

  my %methods = (
    "ENSEMBL_ORTHOLOGUES"   => 2,
    "ENSEMBL_PARALOGUES"    => 1,
    "ENSEMBL_HOMOEOLOGUES"  => 1,
    "ENSEMBL_PROJECTIONS"   => 1,
    "BLASTZ_NET"            => 2,
    "LASTZ_NET"             => 2,
    "TRANSLATED_BLAT_NET"   => 2,
    "ATAC"                  => 2,
    "POLYPLOID"             => 1,
    "LASTZ_PATCH"           => 1,
    "CACTUS_HAL_PW"         => 2,
    "SYNTENY"               => 2
  );

  foreach my $method ( keys %methods ) {
    next if ( $method eq "ENSEMBL_PARALOGUES" && $self->dba->dbc->dbname =~ /master/ );
    my $mlsss = $mlss_adap->fetch_all_by_method_link_type($method);

    foreach my $mlss ( @$mlsss ) {
      my $allowable_count = $methods{$method};
      my $mlss_name = $mlss->name;
      my $mlss_id = $mlss->dbID;
      my $species_set = $mlss->species_set;
      my $species_set_name = $species_set->name;
      my $species_set_id = $species_set->dbID;
      my $gdbs = $species_set->genome_dbs;
      my $gdb_count = scalar( @$gdbs );

      if ( ($method eq 'LASTZ_NET' || $method eq 'SYNTENY') && ($gdb_count == 1) && ($species_set_name !~ /-/) ) {
        $allowable_count = 1;
      }

      my $desc = "For MLSS $mlss_name there are $allowable_count genome_dbs for species_set $species_set_name ($species_set_id), as expected";

      is( $gdb_count, $allowable_count, $desc );
      if ( $mlss_name =~ /(^[0-9]+) / ) {
        is($1, $gdb_count, "species_set $species_set_name and mlss $mlss_name both link to $gdb_count genomes");
      }
    }
  }
}

1;

