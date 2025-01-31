=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::DuplicateComparaMemberXref;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'DuplicateComparaMemberXref',
  DESCRIPTION    => 'Check that the compara member_xref table contains only unique rows',
  GROUPS         => ['compara_annot_highlight'],
  DB_TYPES       => ['compara'],
  TABLES         => ['member_xref']
};

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;
  
  my $sql = qq/
    SELECT gene_member_id, dbprimary_acc, external_db_id, count(*)
      FROM member_xref
        GROUP BY gene_member_id, dbprimary_acc, external_db_id
      HAVING count(*) > 1;
  /;
  
  my $desc = "All the rows in member_xref are unique";
  
  is_rows_zero($dbc, $sql, $desc);
  
}

1;

