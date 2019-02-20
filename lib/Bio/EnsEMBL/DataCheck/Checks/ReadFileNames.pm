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

package Bio::EnsEMBL::DataCheck::Checks::ReadFileNames;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ReadFileNames',
  DESCRIPTION => 'Checks that read file names are valid.',
  GROUPS      => ['funcgen', 'regulatory_build', 'funcgen_registration'],
  DB_TYPES    => ['funcgen']
};

sub tests {
  my $self = shift;

  my $read_file_adaptor = $self->dba->get_ReadFileAdaptor;
  my @all_read_files = @{$read_file_adaptor->fetch_all};
  
  foreach my $read_file (@all_read_files) {
      like(
        $read_file->name, 
        qr/^[a-zA-Z0-9_\+\-\:\.]+$/,
        $read_file->name
      );
  }
  return;
}

1;

