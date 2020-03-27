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
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'CheckGenomicAlignMTs',
  DESCRIPTION => 'The multiple alignments should include all the MT sequences',
  GROUPS      => ['compara', 'compara_multiple_alignments'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES    => ['compara'],
  TABLES      => ['dnafrag', 'genome_db', 'genomic_align', 'method_link', 'method_link_species_set', 'species_set']
};

sub skip_tests {
    my ($self) = @_;
    my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
    my @methods = qw( EPO EPO_EXTENDED PECAN );
    my $db_name = $self->dba->dbc->dbname;

    my @mlsses;
    foreach my $method ( @methods ) {
      my $mlss = $mlss_adap->fetch_all_by_method_link_type($method);
      push @mlsses, @$mlss;
    }

    if ( scalar(@mlsses) == 0 ) {
      return( 1, "There are no multiple alignments in $db_name" );
    }

}

sub tests {
  my ($self) = @_;
  
  my $helper  = $self->dba->dbc->sql_helper;
  
  #Collect all the dnafrags that have a mitochondrion component and should be in a multiple alignment
  my $mlss_sql = q/
    SELECT genome_db.name AS gdb_name, 
        method_link_species_set_id, 
        dnafrag_id, 
        method_link_species_set.name AS mlss_name
      FROM method_link_species_set 
        JOIN method_link USING(method_link_id)
        JOIN species_set USING(species_set_id)
        JOIN genome_db USING(genome_db_id)
        JOIN dnafrag USING(genome_db_id)
      WHERE cellular_component = 'MT' 
        AND type IN ("EPO", "EPO_EXTENDED", "PECAN")
    /;
  
  my $entries_array = $helper->execute(  
    -SQL => $mlss_sql, 
    -USE_HASHREFS => 1
  );
  
  SKIP: {
    skip 'None of the species included in multiple alignments have a mitochondrion' unless scalar(@$entries_array);

    #Checking to make sure that there is at least one row in genomic for each mlss with dnafrag_id linked to MT
    foreach my $row (@$entries_array) {
      my $sql = qq/
        SELECT count(*)
          FROM genomic_align
        WHERE method_link_species_set_id = $row->{method_link_species_set_id}
          AND dnafrag_id = $row->{dnafrag_id}
      /;

      my $desc = "The MT of $row->{gdb_name} (dnafrag_id $row->{dnafrag_id}) is not present in the genomic_align table for alignment mlss_id $row->{method_link_species_set_id} ($row->{mlss_name})";

      is_rows_nonzero($self->dba, $sql, $desc);
    }
  }
}

1;
