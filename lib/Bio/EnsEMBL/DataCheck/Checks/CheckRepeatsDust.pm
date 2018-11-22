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

package Bio::EnsEMBL::DataCheck::Checks::CheckRepeatsDust;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckRepeatsDust',
  DESCRIPTION    => 'dust repeats exist',
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core']
};

sub tests {
  my ($self) = @_;

  ## TODO: Test using the API to make collection aware
  #my $species_id = $self->dba->species_id;

  my $desc_1 = 'dust repeats exist';

  my $sql_1 = q/
    SELECT COUNT(*) FROM repeat_feature
    INNER JOIN analysis USING (analysis_id)
    WHERE logic_name = 'dust'
  /;

 is_rows_nonzero( $self->dba, $sql_1, $desc_1)

}

1;

