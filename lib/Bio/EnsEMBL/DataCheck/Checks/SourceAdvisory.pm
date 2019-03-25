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

package Bio::EnsEMBL::DataCheck::Checks::SourceAdvisory;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'SourceAdvisory',
  DESCRIPTION    => 'Source table contains descriptions and the same dbSNP version',
  DATACHECK_TYPE => 'advisory',
  GROUPS         => ['variation_import'],
  DB_TYPES       => ['variation'],
  TABLES         => ['source']
};

sub tests {
  my ($self) = @_;

  my $desc_desc = 'Source description length';
  my $diag_desc = 'Source has long description'; 
  my $sql_desc = qq/
      SELECT source_id
      FROM source
      WHERE length(description) > 100 
      AND data_types = 'variation'
  /;
  is_rows_zero($self->dba, $sql_desc, $desc_desc, $diag_desc);

  my $desc_version = 'Different versions set for dbSNP sources'; 
  my $sql_version = qq/
      SELECT DISTINCT version 
      FROM source
      WHERE name like '%dbSNP%'
  /; 
  cmp_rows($self->dba, $sql_version, '<=', 1, $desc_version);

  my $desc_missing = 'Source has description';
  my $diag_missing = 'Source description is missing';
  has_data($self->dba, 'source', 'description', 'source_id', $desc_missing, $diag_missing); 

  my $desc_url = 'Source has URL';
  my $diag_url = 'Source URL is missing';
  has_data($self->dba,'source', 'url', 'source_id', $desc_url, $diag_url);

}

1;

