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

package Bio::EnsEMBL::DataCheck::Checks::Publication;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'Publication',
  DESCRIPTION => 'There are no duplicated publication entries',
  GROUPS      => ['variation_import'],
  DB_TYPES    => ['variation'],
  TABLES      => ['publication']
};

sub tests {
  my ($self) = @_;

  my $desc_title = 'Publication has title';
  my $diag_title = 'Publication title is missing';
  has_data($self->dba, 'publication', 'title', 'publication_id', $desc_title, $diag_title);

  my $desc_ids = 'Publication with pmid, pmcid or doi';
  my $diag_ids = 'Publication with no pmid, pmcid and doi';
  my $sql_ids = qq/
      SELECT publication_id
      FROM publication
      WHERE pmid IS NULL
      AND pmcid IS NULL
      AND doi IS NULL
  /;
  is_rows_zero($self->dba, $sql_ids, $desc_ids, $diag_ids);

  my $desc = 'Publication duplicated pmid, pmcid, doi';
  $self->checkDuplicatedValues('publication', 'pmid', $desc, 'Publication is duplicated on pmid');
  $self->checkDuplicatedValues('publication', 'pmcid', $desc, 'Publication is duplicated on pmcid');
  $self->checkDuplicatedValues('publication', 'doi', $desc, 'Publication is duplicated on doi');

}

sub checkDuplicatedValues {
  my ($self, $table, $column, $desc, $diag) = @_;

  my $sql = qq/
      SELECT $column
      FROM $table
      GROUP BY $column 
      HAVING COUNT(*) > 1
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

1;

