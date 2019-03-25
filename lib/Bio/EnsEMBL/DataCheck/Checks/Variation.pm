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

package Bio::EnsEMBL::DataCheck::Checks::Variation;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'Variation',
  DESCRIPTION => 'Variation table data is present and correct',
  GROUPS      => ['variation_tables'],
  DB_TYPES    => ['variation'],
  TABLES      => ['variation ']
};

sub tests {
  my ($self) = @_;
  
  my $desc_1 = 'Variation evidence_attribs is not empty string';
  my $sql_1  = qq/
    SELECT COUNT(*) 
    FROM variation
    WHERE evidence_attribs = ''
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);

  my $desc_2 = 'Variation minor_allele_freq <= 0.5';
  my $sql_2  = qq/
    SELECT COUNT(*) 
    FROM variation
    WHERE minor_allele_freq > 0.5
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2);
  
  my $desc_3 = 'Failed variants that display have citations or phenotypes';
  my $sql_3  = qq/
    SELECT COUNT(v.variation_id)
    FROM variation v 
         JOIN failed_variation fv ON (v.variation_id = fv.variation_id) 
         LEFT JOIN variation_citation vc ON (v.variation_id = vc.variation_id) 
         LEFT JOIN phenotype_feature pf ON (v.name = pf.object_id)
    WHERE v.display = 1
     AND vc.variation_id IS NULL
     AND pf.phenotype_id IS NULL
    /;
    is_rows_zero($self->dba, $sql_3, $desc_3);  
}

1;
