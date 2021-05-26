=head1 LICENSE

Copyright [2018-2021] EMBL-European Bioinformatics Institute

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
  NAME        => 'SpeciesCommonName',
  DESCRIPTION => 'Meta key species.common_name should be same for species form a group of strains or breed',
  GROUPS      => ['core', 'meta'],
  DB_TYPES    => ['core'],
  TABLES      => ['meta'],
};

sub tests {
  my ($self) = @_;
  my $mca = $self->dba->get_adaptor("MetaContainer");
  my $strain_group = $mca->single_value_by_key('species.strain_group'); 
  my $species_common_name = $mca->single_value_by_key('species.common_name');
  my $division = $mca->single_value_by_key('species.division');
  if ($species_common_name eq ''){
	fail("Meta key species.common_name is empty/not set ");
  }
  elsif ( $strain_group ) {   
	$self->check_common_name($division, $species_common_name, $strain_group);
  }
  else{
	skip('No Strains or Breeds for Species');
  }

}

sub check_common_name {
  #This Function checking for common names across all the dbs for specific strain group in a division,
  #Which deviating from the other Datachecks.

  my ($self, $division, $species_common_name,  $strain_group) = @_;
  my $gdba = $self->get_dba("multi", "metadata")->get_GenomeInfoAdaptor();
  my %unique_common_name;
  for my $genome (@{$gdba->fetch_all_by_division($division)}) {
        if($genome->reference() and $genome->reference() eq $strain_group){
        	my $strain_name = $genome->name;
        	my $strain_dba = $self->get_dba($strain_name, 'core');
        	my $desc_strain_dba = "Core database for $strain_name found";
        	my $pass = ok(defined $strain_dba, $desc_strain_dba);
        	next unless $pass;

        	my $mca = $strain_dba->get_adaptor("MetaContainer");
        	my $dbname =  $genome->dbname();
                my $common_name = $mca->single_value_by_key('species.common_name') ? $mca->single_value_by_key('species.common_name')  : "No meta_key species.common_name in $dbname";
                my $desc =  "Meta key species.common_name is similar in DB $dbname for strain group $strain_group";
                is($species_common_name, $common_name, $desc)
       } 
  }    

}


1;

