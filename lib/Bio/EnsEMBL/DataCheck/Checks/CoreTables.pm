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

package Bio::EnsEMBL::DataCheck::Checks::CoreTables;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'CoreTables',
  DESCRIPTION => 'Requisite core-like tables are identical to those in the core database',
  GROUPS      => ['corelike'],
  DB_TYPES    => ['cdna', 'otherfeatures', 'rnaseq'],
  TABLES      => ['assembly', 'coord_system', 'seq_region', 'seq_region_attrib']
};

sub tests {
  my ($self) = @_;

  my $helper = $self->dba->dbc->sql_helper();
  my $core_helper = $self->get_dna_dba->dbc->sql_helper();

  foreach my $table (@{$self->tables}) {
    my $desc = "$table is identical in core and core-like database";

    my $sql = "CHECKSUM TABLE $table";

    my $corelike = $helper->execute( -SQL => $sql );
    my $core = $core_helper->execute( -SQL => $sql );
    is($$corelike[0][1], $$core[0][1], $desc);
  }
}

1;
