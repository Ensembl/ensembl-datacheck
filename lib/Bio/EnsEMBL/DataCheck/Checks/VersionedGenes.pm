=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::VersionedGenes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'VersionedGenes',
  DESCRIPTION => 'Genes are versioned in vertebrate databases, and unversioned in non-vertebrate databases',
  GROUPS      => ['core', 'geneset'],
  DB_TYPES    => ['core'],
  TABLES      => ['coord_system', 'exon', 'exon_transcript', 'gene', 'seq_region', 'transcript', 'translation']
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;

  my $mca = $self->dba->get_adaptor('MetaContainer');
  my $methods = $mca->list_value_by_key('genebuild.method');

  # If the geneset has been produced in-house, the 'method' meta_key
  # will have one of the following values:
  # full_genebuild, projection_build, mixed_strategy_build, maker_genebuild
  my $version_expected = 0;
  foreach my $method (@$methods) {
     if ($method =~ /build/ or $method eq 'anno' or $method eq 'braker' or $method eq 'standard' or $method eq 'manual_annotation') {
        $version_expected = 1;
    }
  }

  $self->version_check('gene',       $version_expected, $species_id);
  $self->version_check('transcript', $version_expected, $species_id);
  $self->version_check('exon',       $version_expected, $species_id);

  $self->translation_version_check($version_expected, $species_id);
}

sub version_check {
  my ($self, $table, $version_expected, $species_id) = @_;

  my ($desc, $diag, $condition);
  if ($version_expected) {
    $desc = ucfirst($table).'s are versioned';
    $diag = "Unversioned $table";
    $condition = "AND $table.version IS NULL"
  } else {
    $desc = ucfirst($table).'s are unversioned';
    $diag = "Versioned $table";
    $condition = "AND $table.version IS NOT NULL"
  }

  my $sql  = qq/
	SELECT $table.stable_id, $table.version FROM
	  $table INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
	WHERE cs.species_id = $species_id
      $condition
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

sub translation_version_check {
  my ($self, $version_expected, $species_id) = @_;

  my ($desc, $diag, $condition);
  if ($version_expected) {
    $desc = 'Translations are versioned';
    $diag = "Unversioned translation";
    $condition = "AND tn.version IS NULL"
  } else {
    $desc = 'Translations are unversioned';
    $diag = "Versioned translation";
    $condition = "AND tn.version IS NOT NULL"
  }

  my $sql  = qq/
	SELECT tn.stable_id, tn.version FROM
	  translation tn INNER JOIN
	  transcript tt USING (transcript_id) INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
	WHERE cs.species_id = $species_id
      $condition
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);

}

1;
