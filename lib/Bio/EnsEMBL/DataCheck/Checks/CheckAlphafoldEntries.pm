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
  NAME           => 'CheckAlphaFoldFormat',
  DESCRIPTION    => 'Check records for alphafold import',
  GROUPS         => ['protein_feature'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['protein_feature', 'analysis'],
};

sub tests {
  my ($self) = @_;

  my $desc_1 = "Protein feature with Alpha fold annotation";
  my $sql_1  = q/
    select count(*) from protein_feature pf, analysis a where a.analysis_id = pf.analysis_id and a.logic_name = 'alphafold_import'
  /;
  is_rows_nonzero($self->dba, $sql_1, $desc_1);


  my $desc_2 = "All Alpha fold records with specific format";
  my $sql_2  = q/
    select count(*) from protein_feature pf, analysis a where a.analysis_id = pf.analysis_id and a.logic_name = 'alphafold_import' and pf.hit_name  REGEXP 'AF\-[A-Za-z0-9]+\-F[0-9]+\.[A-Z]'
  /;
  is_rows($self->dba, $sql_2, 1, $desc_2);

  my $des = "compare count of alpha fold records with all alpha fold records of specific format"
  my $sqlexec = $self->dba->dbc->sql_helper;
  my $total_count = $sqlexec->execute_single_result( -SQL => $sql_1 );
  my $format_count = $sqlexec->execute_single_result( -SQL => $sql_2 );
  cmp_ok($total_count, '==', $format_count, $des);
}

1;
