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

package Bio::EnsEMBL::DataCheck::Checks::DisplayableSampleGene;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'DisplayableSampleGene',
  DESCRIPTION => 'Sample gene is displayable and has web_data attached to its analysis',
  GROUPS      => ['core', 'geneset'],
  DB_TYPES    => ['core'],
  TABLES      => ['analysis', 'analysis_description', 'gene', 'meta']
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc_1 = 'Sample gene has displayable analysis';
  my $diag_1 = 'Undisplayed analysis';
  my $sql_1  = qq/
      SELECT gene_id 
        FROM gene g
  INNER JOIN meta m 
          ON g.stable_id = m.meta_value 
         AND m.meta_key = 'sample.gene_param'
  INNER JOIN analysis a ON g.analysis_id = a.analysis_id
  INNER JOIN analysis_description ad 
          ON g.analysis_id = ad.analysis_id AND ad.displayable = 0
    /;

  is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

  my $desc_2 = 'Sample gene has associated web_data';
  my $diag_2 = 'web_data is not set';
  my $sql_2  = qq/
      SELECT gene_id 
        FROM gene g
  INNER JOIN meta m 
          ON g.stable_id = m.meta_value 
         AND m.meta_key = 'sample.gene_param'
  INNER JOIN analysis a ON g.analysis_id = a.analysis_id
  INNER JOIN analysis_description ad 
          ON g.analysis_id = ad.analysis_id AND ad.web_data IS NULL
    /;

  is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2); 

}

1;

