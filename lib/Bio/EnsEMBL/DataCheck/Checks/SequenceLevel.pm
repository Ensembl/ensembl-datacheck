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

package Bio::EnsEMBL::DataCheck::Checks::SequenceLevel;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SequenceLevel',
  DESCRIPTION => 'Check that DNA is attached and only attached to sequence-level seq_regions.',
  DB_TYPES    => ['core'],
  TABLES      => ['coord_system', 'dna', 'seq_region'],
  GROUPS      => ['handover'],
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;

  SKIP: {
    # ENSCORESW-2719: contig can be not null if only one assembly is stored
    skip "no more than one assembly in coord_system" unless $self->several_assemblies();
    
    my $desc_1 = 'Contig coord_systems have null versions';
    my $sql_1  = qq/
      SELECT COUNT(*) FROM coord_system
      WHERE
        name = 'contig' AND
        version IS NOT NULL AND 
        species_id = $species_id
    /;
    is_rows_zero($self->dba, $sql_1, $desc_1);
  }

  my $desc_2 = 'Coordinate systems with sequence have sequence_level attribute';
  my $diag_2 = 'Coordinate system has seq_regions with sequence but no sequence_level attribute';
  my $sql_2  = qq/
    SELECT DISTINCT cs.name FROM
      coord_system cs INNER JOIN
      seq_region s USING (coord_system_id) INNER JOIN
      dna d USING (seq_region_id) 
    WHERE
      cs.attrib NOT RLIKE 'sequence_level' AND
      cs.species_id = $species_id
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);
}

sub several_assemblies {
  my ($self) = @_;
  
  my $helper = $self->dba->dbc->sql_helper;
  my $sql  = qq/
    SELECT COUNT(*) FROM coord_system
    WHERE
      name = 'chromosome'
  /;
  my $count = $helper->execute_single_result( -SQL => $sql );
  
  return $count > 1;
}

1;
