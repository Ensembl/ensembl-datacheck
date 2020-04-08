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

package Bio::EnsEMBL::DataCheck::Checks::DisplayXrefExists;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'DisplayXrefExists',
  DESCRIPTION    => 'At least one gene name exists',
  GROUPS         => ['core', 'xref'],
  DATACHECK_TYPE => 'advisory',
  TABLES         => ['coord_system', 'gene', 'seq_region', 'transcript', 'xref'],
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  foreach my $type ("gene", "transcript") {
    my $desc = "${type}s have names set via display_xref_id";
    my $sql  = qq/
      SELECT COUNT(*) FROM $type t
        INNER JOIN seq_region sr USING (seq_region_id) 
        INNER JOIN coord_system cs USING (coord_system_id)   
      WHERE cs.species_id = $species_id
        AND t.display_xref_id IS NOT NULL 
    /;

    is_rows_nonzero($self->dba, $sql, $desc);
  }
}

1;
