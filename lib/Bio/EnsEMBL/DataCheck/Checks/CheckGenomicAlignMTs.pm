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

package Bio::EnsEMBL::DataCheck::Checks::CheckGenomicAlignMTs;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::Utils::SqlHelper;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'CheckGenomicAlignMTs',
  DESCRIPTION => 'There should be an entry in genomic_align per genome with multiple alignment MLSS',
  GROUPS      => ['compara', 'compara_multiple_alignments'],
  DB_TYPES    => ['compara'],
  TABLES      => ['dnafrag', 'genome_db', 'genomic_align', 'method_link', 'method_link_species_set', 'species_set']
};

sub tests {
  my ($self) = @_;
  
  my $helper  = $self->dba->dbc->sql_helper;
  
  my $mlss_sql = q/
    SELECT genome_db.name, method_link_species_set_id, dnafrag_id
      FROM method_link_species_set 
        LEFT JOIN method_link USING(method_link_id)
        LEFT JOIN species_set USING(species_set_id)
        LEFT JOIN genome_db USING(genome_db_id)
        LEFT JOIN dnafrag USING(genome_db_id)
      WHERE cellular_component = 'MT' 
        AND (class LIKE 'GenomicAlignTree%' 
        OR class LIKE 'GenomicAlign%multiple%') 
        AND (type NOT LIKE 'CACTUS_HAL%')
    /;
  
  my $entries_array = $helper->execute(  
    -SQL => $mlss_sql, 
    -USE_HASHREFS => 1,
    -CALLBACK     => sub {
      my $row = shift @_;
      return { gdb_name => $row->{name}, mlss_id => $row->{method_link_species_set_id}, dnafrag_id => $row->{dnafrag_id} };
    },
  );
  
  foreach my $row (@$entries_array) {
    my $sql = qq/
      SELECT count(*) 
        FROM genomic_align 
      WHERE method_link_species_set_id = $row->{mlss_id} 
        AND dnafrag_id = $row->{dnafrag_id}
    /;
    
    my $desc = "mlss_id $row->{mlss_id} with dnafrag_id $row->{dnafrag_id} is present in genomic_align";
    
    is_rows_nonzero($self->dba, $sql, $desc);
  }
}

1;

