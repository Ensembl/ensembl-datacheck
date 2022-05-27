=head1 LICENSE

Copyright [2018-2022] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::MetaKeyBRC4;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'MetaKeyBRC4',
  DESCRIPTION    => 'Expected meta keys for BRC4 cores',
  GROUPS         => ['brc4_core'],
  DB_TYPES       => ['core'],
  TABLES         => ['meta']
};

sub tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");

  my @expected = qw/
  assembly.accession
  species.taxonomy_id
  BRC4.component
  BRC4.organism_abbrev
  /;
  foreach my $meta_key (@expected) {
    my $values = $mca->list_value_by_key($meta_key);

    my $desc = "There is one value for meta_key $meta_key";
    ok(scalar(@$values) == 1, $desc);
  }
  
  my $desc = "BRC4 component is valid";
  my %ok_components = map { $_ => 1 } qw(
    AmoebaDB
    CryptoDB
    FungiDB
    GiardiaDB
    HostDB
    MicrosporidiaDB
    PiroplasmaDB
    PlasmoDB
    ToxoDB
    TrichDB
    TriTrypDB
    VectorBase
  );
  my ($component) = @{ $mca->list_value_by_key("BRC4.component") };
  if ($component) {
    ok(exists $ok_components{$component}, $desc);
  }
}

1;
