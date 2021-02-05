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

package Bio::EnsEMBL::DataCheck::Checks::CompareProteinFunctionPredictions;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareProteinFunctionPredictions',
  DESCRIPTION    => 'Compare protein function predictions and prediction attributes between two databases, categorised by analysis',
  GROUPS         => ['compare_variation'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['variation'],
  TABLES         => ['attrib', 'protein_function_predictions', 'protein_function_predictions_attrib']
};

sub tests {
  my ($self) = @_;

  my $old_dba = $self->get_old_dba();

  skip 'No old version of database', 1 unless defined $old_dba;

  my $desc_1 = "Consistent protein function prediction attribute counts by analysis between ".
  $self->dba->dbc->dbname.' and '.$old_dba->dbc->dbname;
  my $sql_1  = q/
    SELECT a.value, COUNT(*) 
    FROM protein_function_predictions_attrib pfpa JOIN attrib a 
    ON (a.attrib_id = pfpa.analysis_attrib_id) 
    GROUP BY a.value
  /;
  row_subtotals($self->dba, $old_dba, $sql_1, undef, 0.95, $desc_1);

  my $desc_2 = "Consistent protein function prediction counts by analysis between ".
  $self->dba->dbc->dbname.' and '.$old_dba->dbc->dbname;
  my $sql_2  = q/
    SELECT a.value, COUNT(*) 
    FROM protein_function_predictions pfp JOIN attrib a 
    ON (a.attrib_id = pfp.analysis_attrib_id) 
    GROUP BY a.value
  /;
  row_subtotals($self->dba, $old_dba, $sql_2, undef, 0.95, $desc_2);
}

1;

