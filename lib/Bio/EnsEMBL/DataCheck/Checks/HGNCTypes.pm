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
  PER_DB         => 1
};

sub tests {
  my ($self) = @_;
  #note these are looking for the *wrong* assignments
  my %check_type =(
    "HGNC_curated_gene"=> "Transcript",
    "HGNC_automatic_gene" => "Transcript",
    "HGNC_curated_transcript" => "Gene",
    "HGNC_curated_transcript" =>"Gene"
  );

  foreach ((my ($source, $wrong) = each %check_type)) {

    my $desc_1 = "All $source  xrefs assigned to correct object type";
    my $sql_1  = qq/
      SELECT COUNT(*) FROM xref x, external_db e, object_xref ox 
      WHERE e.external_db_id=x.external_db_id 
      AND x.xref_id=ox.xref_id AND e.db_name='$source'
      AND ox.ensembl_object_type='$wrong'
    /;

    is_rows_zero($self->dba, $sql_1, $desc_1);
  }

}

1;

