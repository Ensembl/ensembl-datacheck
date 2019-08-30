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

package Bio::EnsEMBL::DataCheck::Checks::GeneStableIdDisplayXref;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'GeneStableIdDisplayXref',
  DESCRIPTION    => 'Genes display_xref does not have display_label set as stable_id',
  GROUPS         => ['xref'],
  DB_TYPES       => ['core'],
  TABLES         => ['gene', 'xref']
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;
  my $desc = 'No Genes found with stable_id set as display_xrefs';
  my $diag = 'Genes found with stable_id set as display_xrefs';
  my $sql  = qq/
    SELECT stable_id FROM
      gene g JOIN 
      xref x on (g.display_xref_id=x.xref_id) JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE x.display_label=g.stable_id AND
      cs.species_id = $species_id
  /;

  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;