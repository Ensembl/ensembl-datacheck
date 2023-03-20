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

package Bio::EnsEMBL::DataCheck::Checks::ProteinFunctionPredictions;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ProteinFunctionPredictions',
  DESCRIPTION => 'Protein function predictions are present and correct',
  GROUPS      => ['variation'],
  DB_TYPES    => ['variation'],
  TABLES      => ['protein_function_predictions']
};

sub skip_tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor('MetaContainer');
  my $vcf = $mca->list_value_by_key('variation_source.vcf')->[0] || 0;

  if ($vcf) {
    return( 1, "Protein function predictions are not expected for species whose variation source is VCF." );
  }
}

sub tests {
  my ($self) = @_;

  my $desc1 = 'protein_function_predictions has one or more rows';
  my $sql1  = qq/
    SELECT COUNT(*) FROM protein_function_predictions
  /;
  is_rows_nonzero($self->dba, $sql1, $desc1);

  my $desc2 = 'prediction_matrix is NOT NULL or empty';
  my $sql2  = qq/
    SELECT COUNT(*) FROM protein_function_predictions
    WHERE prediction_matrix IS NULL OR prediction_matrix = ''
  /;
  is_rows_zero($self->dba, $sql2, $desc2);

  sub has_predictor_data {
    my ($self, $type, $table) = @_;

    # Check if data type is found in 'meta' table
    my $type_in_meta = $self->dba->dbc->db_handle->selectrow_array(
      sprintf('SELECT COUNT(*) > 0 FROM meta WHERE meta_key LIKE "%s%%";', $type));

    my $sql = qq/
     SELECT COUNT(*)
     FROM %s pfp JOIN attrib a
     ON (a.attrib_id = pfp.analysis_attrib_id)
     WHERE a.value LIKE "%s%%";
    /;
    $sql = sprintf($sql, $table, $type);

    my ($desc, $diag);
    if ($type_in_meta) {
      # If found in meta, data for that data type should be available
      $desc = sprintf("%s has data in meta and %s", $type, $table);
      is_rows_nonzero($self->dba, $sql, $desc);
    } else {
      # If not found in meta, no data should be available for that data type
      $desc = sprintf("%s doesn't have data in meta and %s", $type, $table);
      $diag = sprintf(
        "Entry containing '%s' is missing from meta table, but data found for %s in %s",
        $type, $type, $table);
      is_rows_zero($self->dba, $sql, $desc, $diag);
    }
  }
  $self->has_predictor_data("sift",     "protein_function_predictions");
  $self->has_predictor_data("sift",     "protein_function_predictions_attrib");
  $self->has_predictor_data("cadd",     "protein_function_predictions");
  $self->has_predictor_data("dbnsfp",   "protein_function_predictions");
  $self->has_predictor_data("polyphen", "protein_function_predictions");

}

1;
