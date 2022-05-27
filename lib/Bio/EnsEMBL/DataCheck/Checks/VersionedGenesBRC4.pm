=head1 LICENSE

Copyright [2018-2022] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::VersionedGenesBRC4;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'VersionedGenesBRC4',
  DESCRIPTION => 'Genes are unversioned in BRC4 databases',
  GROUPS      => ['brc4_core'],
  DB_TYPES    => ['core'],
  TABLES      => ['coord_system', 'gene', 'seq_region', 'transcript', 'translation']
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;

  $self->version_check('gene',        $species_id);
  $self->version_check('transcript',  $species_id);
  $self->version_check('exon',        $species_id);

  $self->translation_version_check($species_id);
}

sub version_check {
  my ($self, $table, $species_id) = @_;

  my $desc = ucfirst($table).'s are versioned';
  my $diag = "Unversioned $table";
  my $sql  = qq/
	SELECT $table.stable_id, $table.version FROM
	  $table INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
	WHERE cs.species_id = $species_id
      AND $table.version IS NULL
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

sub translation_version_check {
  my ($self, $species_id) = @_;

  my $desc = 'Translations are versioned';
  my $diag = "Unversioned translation";
  my $sql  = qq/
	SELECT tn.stable_id, tn.version FROM
	  translation tn INNER JOIN
	  transcript tt USING (transcript_id) INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
	WHERE cs.species_id = $species_id
      AND tn.version IS NULL
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);

}

1;
