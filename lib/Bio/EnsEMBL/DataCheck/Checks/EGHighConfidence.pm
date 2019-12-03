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

package Bio::EnsEMBL::DataCheck::Checks::EGHighConfidence;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'EGHighConfidence',
  DESCRIPTION    => 'Checks that the HighConfidenceOrthologs pipeline has been run',
  GROUPS         => ['compara', 'compara_protein_trees'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['homology']
};

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;
  
  my $sql = q/
    SELECT COUNT(*) 
      FROM homology 
    WHERE is_high_confidence IS NOT NULL
  /;
  
  my $desc = "Homologies have been annotated with a confidence value";
  
  is_rows_zero($dbc, $sql, $desc);
}

1;

