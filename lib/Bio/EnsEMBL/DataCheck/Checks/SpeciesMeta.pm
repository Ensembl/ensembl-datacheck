=head1 LICENSE

Copyright [2018] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::SpeciesMeta;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SpeciesMeta',
  DESCRIPTION => 'Check the presence and format of species-related meta keys',
  GROUPS      => ['core_handover'],
  DB_TYPES    => ['core'],
  TABLES      => ['meta']
};

sub tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");

  my %formats = (
    'species.division'        => 'Ensembl(Bacteria|Fungi|Metazoa|Plants|Protists|Vertebrates)',
    'species.production_name' => '[a-z0-9]+_[a-z0-9_]+',
    'species.scientific_name' => '[A-Z][a-z0-9]+ [\w \(\)]+',
    'species.url'             => '[A-Z][a-z0-9]+_[A-Za-z0-9_]+',
  );

  foreach my $meta_key (sort keys %formats) {
    my $desc   = "$meta_key has correct format";
    my $format = $formats{$meta_key};
    my $value  = $mca->single_value_by_key($meta_key);
    like($value, qr/^$format$/, $desc);
  }
}

1;

