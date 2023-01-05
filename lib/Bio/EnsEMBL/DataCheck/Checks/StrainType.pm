=head1 LICENSE
Copyright [2018-2023] EMBL-European Bioinformatics Institute
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

package Bio::EnsEMBL::DataCheck::Checks::StrainType;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'StrainType',
  DESCRIPTION    => 'The strain type must be from an approved list',
  GROUPS         => ['rapid_release'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['meta']
};

sub tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");
 SKIP: {
     # Check that the strain.type conforms to expectations
     my $types = 'strain|cultivar|breed|haplotype|ecotype';
     
     my $desc = "Strain type is allowed";
     my $strain_type = $mca->single_value_by_key('strain.type');
     
     skip 'strain.type meta key does not exist', 1 unless defined $strain_type;
     
     like($strain_type, qr/^$types$/, $desc);
  }
}
1;
