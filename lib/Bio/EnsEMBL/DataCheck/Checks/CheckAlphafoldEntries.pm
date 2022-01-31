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

package Bio::EnsEMBL::DataCheck::Checks::CheckAlphafoldEntries;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckRecords',
  DESCRIPTION    => 'Check records for alphafold import',
  GROUPS         => ['ontologies'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['protein_feature'],
};

sub tests {
  my ($self) = @_;

  my $desc_1 = 'count of protein feature table greater than 0';
  my $sql_1  = q/
    select count(*) from protein_feature pf, analysis a where a.analysis_id = pf.analysis_id and a.logic_name = 'alphafold_import'
  /;
  is_rows_nonzero($self->dba, $sql_1, $desc_1);


  my $desc = "check format";
  my $sql = "SELECT hit_name FROM protein_feature WHERE hit_name like 'AF-%-F1._'";
  is_rows($self->dba, $sql, 1, $desc);
}

1;
