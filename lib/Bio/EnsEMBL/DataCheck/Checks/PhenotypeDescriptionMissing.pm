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

package Bio::EnsEMBL::DataCheck::Checks::PhenotypeDescriptionMissing;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'PhenotypeDescriptionMissing',
  DESCRIPTION => 'Phenotype does not have empty descriptions',
  GROUPS      => ['variation_import'], 
  DB_TYPES    => ['variation'],
  TABLES      => ['phenotype']
};

sub tests {
  my ($self) = @_;

  my $desc = 'Phenotype has description';
  my $diag = 'Phenotype description is missing';
  has_data($self->dba, 'phenotype', 'description', 'phenotype_id', $desc, $diag); 

}

1;

