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

package Bio::EnsEMBL::DataCheck::Checks::AnalysisFormat;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'AnalysisFormat',
  DESCRIPTION => 'Analysis logic name and date are formatted correctly',
  GROUPS      => ['core', 'corelike'],
  DB_TYPES    => ['cdna', 'core', 'otherfeatures', 'rnaseq'],
  TABLES      => ['analysis'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  my $desc_1 = 'Logic names are lower case';
  my $sql_1  = q/
    SELECT logic_name FROM analysis
    WHERE BINARY logic_name <> lower(logic_name)
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);

  my $desc_2 = 'Created date is not all zeroes';
  my $sql_2  = q/
    SELECT logic_name FROM analysis
    WHERE
      created = '0000-00-00 00:00:00' OR
      created = '1970-00-00 00:00:00'
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2);
}

1;
