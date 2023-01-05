=head1 LICENSE

Copyright [2018-2023] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::MLSSTagThresholdDs;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::Compara;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MLSSTagThresholdDs',
  DESCRIPTION => 'Threshold values for ds exist, if appropriate',
  GROUPS      => ['compara', 'compara_gene_trees', 'compara_gene_tree_pipelines'],
  DB_TYPES    => ['compara'],
  TABLES      => ['method_link', 'method_link_species_set', 'method_link_species_set_attr']
};

sub tests {
  my ($self) = @_;

  my $sql_count = 'SELECT ds FROM homology WHERE ds IS NOT NULL LIMIT 1';
  my $sql_1  = q/
    SELECT COUNT(*) FROM method_link_species_set_attr
    WHERE threshold_on_ds IS NOT NULL
  /;
  my $sql_2  = q/
    SELECT COUNT(*) FROM method_link_species_set_attr
    WHERE threshold_on_ds IS NOT NULL AND threshold_on_ds NOT IN (1,2)
  /;
  
  if ( sql_count($self->dba, $sql_count) ) {
    my $desc_1 = 'ds threshold defined for at least one row';
    is_rows_nonzero($self->dba, $sql_1, $desc_1);
    
    my $desc_2 = 'ds threshold defined for at least one row';
    is_rows_zero($self->dba, $sql_2, $desc_2);

  } else {
    my $desc_3 = 'ds threshold not defined';
    is_rows_zero($self->dba, $sql_1, $desc_3);

  }
}

1;
