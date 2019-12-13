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
  
  foreach my $mlss ( @$mlss ) {
    my $mlss_name = $mlss->name;
    my $mlss_id = $mlss->dbID;
    my $species_set = $mlss->species_set;
    my $species_set_name = $species_set->name;
    my $species_set_id = $species_set->dbID;
    my $method = $mlss->method->type;
    my $gdbs = $species_set->genome_dbs;
    my $gdb_count = scalar( @$gdbs );
    
    if ( $mlss_name =~ /(^[0-9]+) / ) {
      is($1, $gdb_count, "species_set $species_set_name and mlss $mlss_name both link to $gdb_count genomes");
    }

    if ( $mlss_name =~ /^([a-zA-Z]+) /  ) {
      my $mlss_p1 = $1;
      my $desc_1 = "The current convention is in place for mlss $mlss_name and species_set $species_set_name";
      unlike( $mlss_name, qr/^(protein|nc|species)/, $desc_1 );
      my $desc_2 = "species_set $species_set_id for mlss $mlss_name starts with the species_set name $species_set_name";

      if ( $species_set_name =~ /collection/ ) {
        is( $species_set_name, "collection-$mlss_p1", $desc_2 );
      }
      else {
        is( $species_set_name, $mlss_p1, $desc_2 );
      }
    }
    next if ( $method eq "ENSEMBL_PARALOGUES" && $self->dba->dbc->dbname =~ /master/ );
    next if ( !exists $methods{$method} );
    my $allowable_count = $methods{$method};
    unless ( $mlss_name =~ /$species_set_name/ ) {
      my $desc = "For MLSS $mlss_name there are $allowable_count genome_dbs for species_set $species_set_name, as expected";
      is( $gdb_count, $allowable_count, $desc );
    }
  }
}

1;
