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

package Bio::EnsEMBL::DataCheck::Checks::GeneBiotypes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'GeneBiotypes',
  DESCRIPTION => 'Check that genes and transcripts have valid biotypes',
  GROUPS      => ['gene'],
  DB_TYPES    => ['core', 'otherfeatures'],
  TABLES      => ['biotype', 'coord_system', 'gene', 'seq_region', 'transcript']
};

sub tests {
  my ($self) = @_;

  $self->biotypes('gene');
  $self->biotypes('transcript');
}

sub biotypes {
  my ($self, $feature) = @_;
  my $species_id = $self->dba->species_id;
  my $db_type = $self->dba->group;
  
  my $desc = ucfirst($feature)."s have valid biotypes";
  my $diag = "Invalid biotype for $db_type $feature";
  my $sql = qq/
    SELECT t1.stable_id FROM
      $feature t1 INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id) LEFT OUTER JOIN
      biotype t2 ON (
        t1.biotype = t2.name AND
        t2.object_type = '$feature' AND
        FIND_IN_SET('$db_type', db_type)
      )
    WHERE
      t1.biotype IS NOT NULL AND
      t2.name IS NULL AND
      coord_system.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;

