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

package Bio::EnsEMBL::DataCheck::Checks::GeneStrands;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'GeneStrands',
  DESCRIPTION => 'Genes have valid strand values',
  GROUPS      => ['core', 'corelike', 'geneset'],
  DB_TYPES    => ['core', 'otherfeatures'],
  TABLES      => ['coord_system', 'exon', 'gene', 'prediction_exon', 'prediction_transcript', 'seq_region', 'transcript']
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;

  $self->strand_check('gene',       $species_id);
  $self->strand_check('transcript', $species_id);
  $self->strand_check('exon',       $species_id);

  $self->strand_check('prediction_transcript', $species_id);
  $self->strand_check('prediction_exon',       $species_id);
}

sub strand_check {
  my ($self, $table, $species_id) = @_;

  my $desc = $table.' table has valid strand values';
  my $sql  = qq/
	SELECT COUNT(*) FROM
	  $table INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
	WHERE
	  seq_region_strand NOT IN (1, -1) AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql, $desc);
}

1;
