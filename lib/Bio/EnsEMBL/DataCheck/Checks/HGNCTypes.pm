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

package Bio::EnsEMBL::DataCheck::Checks::HGNCTypes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'HGNCTypes',
  DESCRIPTION    => 'Check that HGNC_curated_genes xrefs are on genes, _transcript are on transcript etc',
  GROUPS         => ['core', 'xref'],
  DATACHECK_TYPE => 'critical',
  TABLES         => ['xref'],
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;
  #note these are looking for the *wrong* assignments
  my %check_type =(
   "HGNC" => "Transcript",
   "HGNC_trans_name" => "Gene"
  );
  foreach my $source (keys %check_type) {
    my $table = 'gene';
    my $wrong = $check_type{$source};
    my $desc_1 = "All $source  xrefs assigned to correct object type";
    if ($check_type{$source} eq 'Transcript'){
        $table = 'transcript';
    }
    my $sql_1 = qq/
      SELECT COUNT(*) FROM object_xref ox  
      INNER JOIN xref USING(xref_id) 
      INNER JOIN external_db e USING(external_db_id)
      INNER JOIN ${table} gt ON ox.ensembl_id = gt.${table}_id 
      INNER JOIN seq_region sr USING (seq_region_id) 
      INNER JOIN coord_system cs USING (coord_system_id) 
      WHERE cs.species_id = $species_id
      AND e.db_name='$source'
      AND ox.ensembl_object_type='$wrong'
   /;
   print($sql_1); 

    is_rows_zero($self->dba, $sql_1, $desc_1);
  }

}

1;

