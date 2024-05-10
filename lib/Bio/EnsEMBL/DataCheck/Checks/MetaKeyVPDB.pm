=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::MetaKeyVPDB;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'MetaKeyVPDB',
  DESCRIPTION    => 'Expected meta keys for VEuPathDB cores',
  GROUPS         => ['vpdb_core'],
  DB_TYPES       => ['core'],
  TABLES         => ['meta']
};

sub tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");

  my @expected = qw/
  assembly.accession
  species.taxonomy_id
  veupathdb.build_version
  veupathdb.component_db
  veupathdb.organism_abbrev
  /;
  foreach my $meta_key (@expected) {
    my $values = $mca->list_value_by_key($meta_key);

    my $desc = "There is one value for meta_key $meta_key";
    ok(scalar(@$values) == 1, $desc);
  }
  
  my $desc = "VEuPathDB Component DB is valid";
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
  my ($component) = @{ $mca->list_value_by_key("veupathdb.component_db") };
  if ($component) {
    ok(exists $ok_components{$component}, $desc);
  }
}

1;
