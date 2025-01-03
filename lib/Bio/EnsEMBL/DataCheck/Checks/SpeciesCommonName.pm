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

package Bio::EnsEMBL::DataCheck::Checks::SpeciesCommonName;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'SpeciesCommonName',
  DESCRIPTION    => 'Meta key species.common_name should be same for species from a group of strains or breeds',
  GROUPS         => ['core_sync'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['meta'],
};

sub skip_tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");
  my $strain_group = $mca->single_value_by_key('species.strain_group');

  if ( ! defined $strain_group ) {
    return (1, 'No strains or breeds.');
  }
}

sub tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");

  my $division = $mca->single_value_by_key('species.division');
  my $strain_group = $mca->single_value_by_key('species.strain_group'); 
  my $species_common_name = $mca->single_value_by_key('species.common_name');

  my $desc = "Common name is defined";
  my $pass = ok(defined $species_common_name, $desc);

  if ($pass) {
    $self->check_common_name($division, $species_common_name, $strain_group);
  }
}

sub check_common_name {
  # This function checks for common names across all the dbs for
  # specific strain group in a division, which deviates from the
  # standard datacheck methodology that operates on a single
  # database at a time.

  my ($self, $division, $species_common_name,  $strain_group) = @_;
  my $gdba = $self->get_dba("multi", "metadata")->get_GenomeInfoAdaptor();

  for my $genome (@{$gdba->fetch_all_by_division($division)}) {
    if ($genome->reference() and $genome->reference() eq $strain_group) {
      my $strain_name = $genome->name;
      my $strain_dba = $self->get_dba($strain_name, 'core');
      my $desc_strain_dba = "Core database for $strain_name found";
      my $pass = ok(defined $strain_dba, $desc_strain_dba);
      next unless $pass;

      my $mca = $strain_dba->get_adaptor("MetaContainer");
      my $dbname = $genome->dbname();
      my $common_name = $mca->single_value_by_key('species.common_name');
      my $desc =  "Meta key species.common_name is the same in DB $dbname for strain group $strain_group";
      is($species_common_name, $common_name, $desc)
    }
  }    
}

1;
