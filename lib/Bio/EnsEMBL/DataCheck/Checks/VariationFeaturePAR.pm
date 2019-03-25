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

package Bio::EnsEMBL::DataCheck::Checks::VariationFeaturePAR;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'VariationFeaturePAR',
  DESCRIPTION    => 'Variants do not map to Y PAR',
  GROUPS         => ['variation_tables'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['variation'],
  TABLES         => ['variation_feature']
};

sub skip_tests {
  my ($self) = @_;

  if ($self->species ne 'homo_sapiens') {
    return (1, 'PAR test only applicable to human');
  }
}

# TODO: Review if PAR region can be looked up in core databases
# or variation production database
# +------------------+----------------+--------------+----------------+--------------+
# | genome_reference | X_region_start | X_region_end | Y_region_start | Y_region_end |
# +------------------+----------------+--------------+----------------+--------------+
# | GRCh37           |      154931044 |    155260560 |       59034050 |     59363566 |
# | GRCh37           |          60001 |      2699520 |          10001 |      2649520 |
# | GRCh38           |          10001 |      2781479 |          10001 |      2781479 |
# | GRCh38           |      155701383 |    156030895 |       56887903 |     57217415 |
# +------------------+----------------+--------------+----------------+--------------+
sub tests {
  my ($self) = @_;
  
  my $dna_dba = $self->get_dna_dba();
  my $gca = $dna_dba->get_adaptor("GenomeContainer");
  my $version = $gca->get_version();
  die('No assembly version') if (!$version);
  
  my $desc = 'Variants are not mapped to the Y PAR';
  my $constraint;
  
  if ($version eq 'GRCh38') {
    $constraint = qq/
    (vf.seq_region_start >= 10001 AND vf.seq_region_end <= 2781479)
    OR
    (vf.seq_region_start >= 56887903 AND vf.seq_region_end <= 57217415)
    /;
  } elsif ($version eq 'GRCh37') {
    $constraint = qq/
    (vf.seq_region_start >= 10001 AND vf.seq_region_end <= 2649520)
    OR
    (vf.seq_region_start >=59034050 AND vf.seq_region_end AND vf.seq_region_end <= 59363566)
    /;
  } else {
    die("No PAR regions for assembly $version");
  }
  
  my $sql = qq/
    SELECT COUNT(variation_feature_id) 
    FROM variation_feature vf, seq_region sr 
    WHERE vf.seq_region_id = sr.seq_region_id
    AND sr.name = "Y"
    AND ($constraint)
  /;
  is_rows_zero($self->dba, $sql, $desc);
}

1;
