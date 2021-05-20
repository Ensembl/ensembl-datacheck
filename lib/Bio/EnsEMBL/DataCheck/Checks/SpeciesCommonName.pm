=head1 LICENSE

Copyright [2018-2020] EMBL-European Bioinformatics Institute

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
use Data::Dumper;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SpeciesCommonName',
  DESCRIPTION => 'Meta key species.common_name should be same for group of strains or breed',
  GROUPS      => ['core', 'meta'],
  DB_TYPES    => ['core'],
  TABLES      => ['meta'],
};

sub tests {
  my ($self) = @_;
  my $mca = $self->dba->get_adaptor("MetaContainer");
  my $strain = $mca->single_value_by_key('species.strain');
  my $strain_group = $mca->single_value_by_key('species.strain_group'); 
  my $reference_species_common_name = $mca->single_value_by_key('species.common_name');
  my $division = $mca->single_value_by_key('species.division');
  if ( $strain && $strain_group ) {
        
	$self->CheckCommonName($division, $reference_species_common_name, $strain_group);
  }
  else{
	skip('No Strains or Breeds for Species');
  }

}

sub CheckCommonName {
  my ($self, $division, $reference_species_common_name, $strain_group) = @_;
  my $gdba = $self->registry->get_DBAdaptor("multi", "metadata")->get_GenomeInfoAdaptor();
  my %unique_common_name;
  for my $genome (@{$gdba->fetch_all_by_division($division)}) {
        if($genome->strain() and $genome->reference() and $genome->reference() eq $strain_group){
        	my $mca = $self->registry->get_adaptor( $genome->name(), 'Core', 'MetaContainer' );
                my $common_name = $mca->single_value_by_key('species.common_name');
        	my $dbname =  $genome->dbname();
                push(@{$unique_common_name{$common_name}} , $dbname); 
       } 
  }    

  my $desc='';
  for my $common_name (keys %unique_common_name){
  	$desc.= join("\n$common_name: ", @{$unique_common_name{$common_name}});
  }
  $desc = " Meta key species.common_name is similar in all DBs for strain group $strain_group \n". $desc   ;
  is(keys %unique_common_name ,  1 , $desc) ;
}

1;

