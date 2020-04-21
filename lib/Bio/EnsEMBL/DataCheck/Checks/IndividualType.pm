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

package Bio::EnsEMBL::DataCheck::Checks::IndividualType;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'IndividualType',
  DESCRIPTION => 'Individuals have the correct type for each species',
  GROUPS      => ['variation_import'],
  DB_TYPES    => ['variation'],
  TABLES      => ['individual'],
};

sub tests {
  my ($self) = @_;

  my $species = $self->species; 
  my $desc = 'Individual type is correct';
  my $diag = 'Individual type is incorrect';

  if($species =~ /mus_musculus/) {
    my $sql_1 = q/
        SELECT COUNT(*) 
        FROM individual
        WHERE individual_type_id != 1
    /;
    is_rows_zero($self->dba, $sql_1, $desc, $diag);
  }

  if($species =~ /canis_familiaris|danio_rerio|
                  gallus_gallus|rattus_norvegicus|
                  bos_taurus|ornithorhynchus_anatinus|
                  pongo_abelii/) {
  my $sql_2 = q/
      SELECT COUNT(*)
      FROM individual
      WHERE individual_type_id != 2
  /; 
  is_rows_zero($self->dba, $sql_2, $desc, $diag);
  } 

  if($species =~ /anopheles_gambiae/) {
    my $sql_3 = q/
        SELECT COUNT(*)
        FROM individual
        WHERE individual_type_id != 2
        AND individual_type_id != 3
    /;
    is_rows_zero($self->dba, $sql_3, $desc, $diag);
  }

  if($species =~ /homo_sapiens|pan_troglodytes|tetraodon_nigroviridis/) {
    my $sql_4 = q/
        SELECT COUNT(*)
        FROM individual
        WHERE individual_type_id != 3
    /;
    is_rows_zero($self->dba, $sql_4, $desc, $diag);
  }

  # There are individual records but no species specific individual type checks
  # SKIP the check so that it is not reported as a failure
  SKIP: {
     skip "No individual_type_id check" , 1;
  }

}

1;
