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

package Bio::EnsEMBL::DataCheck::Checks::DuplicateReadNames;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'DuplicateReadNames',
  DESCRIPTION => 'Duplicate read names',
  GROUPS      => ['funcgen', 'regulatory_build', 'funcgen_registration'],
  DB_TYPES    => ['funcgen']
};

sub tests {
  my $self = shift;

  my $desc = "Read file names should be unique";
  my $diag = "Read file names have duplicates";
  
  my $sql = '
    select 
      read_file.name as read_file_name,
      group_concat(experiment.name) experiment_names,
      count(read_file_id) count
    from 
      experiment 
      join read_file_experimental_configuration using (experiment_id)
      join read_file using (read_file_id)
    group by
      read_file_name
    having 
      count>1
  ';

  is_rows_zero(
    $self->dba, 
    $sql, 
    $desc, 
    $diag
  );
  return;
}

1;

