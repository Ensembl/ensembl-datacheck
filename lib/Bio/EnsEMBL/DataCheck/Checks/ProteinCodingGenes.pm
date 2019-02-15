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

package Bio::EnsEMBL::DataCheck::Checks::ProteinCodingGenes;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ProteinCodingGenes',
  DESCRIPTION => 'At least one protein-coding gene exists',
  GROUPS      => ['core', 'geneset'],
  DB_TYPES    => ['core'],
  TABLES      => ['coord_system', 'gene', 'seq_region']
};

sub tests {
  my ($self) = @_;

  my $ga = $self->dba->get_adaptor('Gene');
  my $genes = $ga->fetch_all_by_biotype(['protein_coding']);

  my $desc = 'Protein-coding genes exist';
  ok(scalar(@$genes), $desc);
}

1;
