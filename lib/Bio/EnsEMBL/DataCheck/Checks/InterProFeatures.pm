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

package Bio::EnsEMBL::DataCheck::Checks::InterProFeatures;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'InterProFeatures',
  DESCRIPTION => 'InterPro data is present and correct',
  GROUPS      => ['protein_features'],
  DB_TYPES    => ['core'],
  TABLES      => ['analysis', 'interpro', 'xref'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  my $desc_1 = 'interpro table is populated';
  my $sql_1  = 'SELECT COUNT(*) FROM interpro';
  is_rows_nonzero($self->dba, $sql_1, $desc_1);

  my $desc_2 = 'InterPro terms are stored as xrefs';
  my $sql_2  = qq/
    SELECT interpro_ac FROM
      interpro LEFT OUTER JOIN
      xref ON interpro_ac = dbprimary_acc
    WHERE
      dbprimary_acc IS NULL
  /;
  is_rows_zero($self->dba, $sql_2, $desc_2);

  my $desc_3 = 'InterPro terms have names and descriptions';
  my $sql_3  = qq/
    SELECT dbprimary_acc, display_label, description FROM
      interpro INNER JOIN
      xref ON interpro_ac = dbprimary_acc
    WHERE
      dbprimary_acc = display_label IS NULL OR
      description = '' OR
      description IS NULL
  /;
  is_rows_zero($self->dba, $sql_3, $desc_3);

  my $desc_4 = 'InterPro-derived domain sources have a "db" name';
  my $sql_4  = qq/
    SELECT logic_name FROM
      analysis
    WHERE
      program = 'InterProScan' AND
      (db = '' OR db IS NULL)
  /;
  is_rows_zero($self->dba, $sql_4, $desc_4);
}

1;
