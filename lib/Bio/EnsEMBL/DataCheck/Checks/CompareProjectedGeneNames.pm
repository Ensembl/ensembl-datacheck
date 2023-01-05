=head1 LICENSE

Copyright [2018-2023] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CompareProjectedGeneNames;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw(same_assembly same_geneset);

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareProjectedGeneNames',
  DESCRIPTION    => 'Compare Projected Gene Name counts between two databases',
  GROUPS         => ['compare_core', 'xref', 'xref_gene_symbol_transformer', 'xref_name_projection'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core'],
  TABLES         => ['xref','gene','object_xref','seq_region','coord_system']
};

sub tests {
  my ($self) = @_;

  SKIP: {
    my $old_dba = $self->get_old_dba();

    skip 'No old version of database', 1 unless defined $old_dba;

    my $mca = $self->dba->get_adaptor('MetaContainer');
    my $old_mca = $old_dba->get_adaptor('MetaContainer');

    if (!same_assembly($mca, $old_mca)) {    
      skip 'Current DB has different assembly', 1;
    }
    
    if (!same_geneset($mca, $old_mca)) {    
      skip 'Current DB has different geneset', 1;
    }

    $self->projected_gene_name_counts($old_dba);
  }
}

sub projected_gene_name_counts {
  my ($self, $old_dba) = @_;

  my $threshold = 0.66;

  my $desc = "Checking Projected Gene Names between ".
             $self->dba->dbc->dbname.
             ' (species_id '.$self->dba->species_id.') and '.
             $old_dba->dbc->dbname.
             ' (species_id '.$old_dba->species_id.')';
  my $sql  = qq/
      SELECT COUNT(*) FROM 
        gene g INNER JOIN
        xref x ON g.display_xref_id = x.xref_id  INNER JOIN        
        object_xref ox USING (xref_id)  INNER JOIN
        seq_region sr USING (seq_region_id) INNER JOIN
        coord_system cs USING (coord_system_id)
      WHERE 
        x.info_type = 'PROJECTION' AND
        ox.ensembl_object_type = 'Gene' AND
        cs.species_id = %d
  /;
  my $sql1 = sprintf($sql, $self->dba->species_id);
  my $sql2 = sprintf($sql, $old_dba->species_id);
  row_totals($self->dba, $old_dba, $sql1, $sql2, $threshold, $desc);
}
1;
