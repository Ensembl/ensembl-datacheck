=head1 LICENSE

Copyright [2018-2021] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::AttribValuesExist;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'AttribValuesExist',
  DESCRIPTION    => 'Check that TSL, APPRIS and GENCODE attributes exist',
  GROUPS         => ['geneset_support_level'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['attrib_type', 'transcript', 'transcript_attrib']
};

sub tests {
  my ($self) = @_;
  my $helper = $self->dba->dbc->sql_helper;

  my $desc_1 = 'APPRIS attributes exist';
  my $sql_1  = q/
    SELECT COUNT(*) FROM
      transcript INNER JOIN
      transcript_attrib USING (transcript_id) INNER JOIN
      attrib_type USING (attrib_type_id)
    WHERE code like 'appris%'
  /;
  is_rows_nonzero($self->dba, $sql_1, $desc_1);

  if ($self->species =~ /(homo_sapiens|mus_musculus)/) {
    my $desc_2 = 'All genes have at least one transcript with a gencode_basic attribute';
    my $sql_2a = q/
      SELECT COUNT(distinct gene_id) FROM transcript
      WHERE biotype NOT IN ('LRG_gene')
    /;
    my $sql_2b = q/
      SELECT COUNT(distinct gene_id) FROM
        transcript INNER JOIN
        transcript_attrib USING (transcript_id) INNER JOIN
        attrib_type USING (attrib_type_id) 
      WHERE
        biotype NOT IN ('LRG_gene') AND
        attrib_type.code = 'gencode_basic'
    /;

    my $gene_count    = $helper->execute_single_result( -SQL => $sql_2a );
    my $gencode_count = $helper->execute_single_result( -SQL => $sql_2b );
    is($gencode_count, $gene_count, $desc_2);

    my $desc_3 = 'TSL attributes exist';
    my $sql_3  = q/
      SELECT COUNT(*) FROM
        transcript INNER JOIN
        transcript_attrib USING (transcript_id) INNER JOIN
        attrib_type USING (attrib_type_id)
      WHERE code like 'tsl%'
    /;
    is_rows_nonzero($self->dba, $sql_3, $desc_3);
  }
}

1;
