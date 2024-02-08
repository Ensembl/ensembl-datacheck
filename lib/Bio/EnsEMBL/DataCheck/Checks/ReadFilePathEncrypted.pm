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

package Bio::EnsEMBL::DataCheck::Checks::ReadFilePathEncrypted;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'ReadFilePathEncrypted',
  DESCRIPTION    => 'Checks if paths stored in the file column of the read_file table are encrypted',
  GROUPS         => ['funcgen'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['funcgen'],
  TABLES         => ['read_file']
};

sub tests {
  my ($self) = @_;
  SKIP: {
  my $funcgen_dba = $self->get_dba(undef, 'funcgen');
  skip 'No funcgen database', 1 unless defined $funcgen_dba;

  my $desc = "Check if file column in read_file table is encrypted";
  my $test_name = "ReadFile path encrypted";

  my $sql = "select count(*) from read_file where file like '/%fastq%'";

  is_rows_zero($funcgen_dba, $sql, $test_name, $desc);

  }
}

1;

