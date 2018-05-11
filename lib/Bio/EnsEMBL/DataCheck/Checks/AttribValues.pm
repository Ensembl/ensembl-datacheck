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

package Bio::EnsEMBL::DataCheck::Checks::AttribValues;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'AttribValues',
  DESCRIPTION    => 'TSL, APPRIS, GENCODE and RefSeq attributes exist',
  GROUPS         => ['core_handover'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['assembly_exception', 'attrib_type', 'coord_system', 'gene', 'gene_attrib', 'seq_region', 'seq_region_attrib', 'transcript', 'transcript_attrib']
};

sub tests {
  my ($self) = @_;

}

1;

