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

package Bio::EnsEMBL::DataCheck::Checks::DescriptionDisplayXrefs;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'DescriptionDisplayXrefs',
  DESCRIPTION    => '
                     Tests for {ECO: } blocks from Uniprot in descriptions.
                     Test for Bad characters in display_label
                     Tests for improper import of MIM data.         
                    ',
  GROUPS         => ['core', 'xref'],
  DATACHECK_TYPE => 'critical',
  TABLES         => ['xref'],
  PER_DB         => 1
};

sub tests {
  my ($self) = @_;

  my $desc_1 = 'No {ECO: } blocks from Uniprot in descriptions';
  my $sql_1  = qq/
      SELECT count(*) FROM xref  
      WHERE description like '%{ECO:%}%'
  /;

  is_rows_zero($self->dba, $sql_1, $desc_1);

  my $desc_2 = 'No NULL OR Bad Chracters Found In display_label';
  my $sql_2  = qq/
      SELECT count(*) FROM xref 
      WHERE display_label IS NULL
      OR display_label REGEXP '^[:;\\n\\r\\t~ ]+\$'
  /;

  is_rows_zero($self->dba, $sql_2, $desc_2);

  my $desc_3 = 'No improper import of MIM data.';
  my $sql_3  = qq/
      SELECT count(x.xref_id) FROM xref x, external_db e
      WHERE e.db_name IN ('MIM','MIM_MORBID','MIM_GENE') 
      AND e.external_db_id = x.external_db_id  
      AND x.display_label REGEXP '\\n';
  /;

  is_rows_zero($self->dba, $sql_3, $desc_3);
  

}

1;

