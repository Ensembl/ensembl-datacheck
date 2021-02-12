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

package Bio::EnsEMBL::DataCheck::Checks::HGNCTypes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'HGNCTypes',
  DESCRIPTION => 'HGNC xrefs are attached to the appropriate object',
  GROUPS      => ['core', 'xref'],
  TABLES      => ['external_db', 'object_xref', 'xref'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  my %check_type = (
   "HGNC" => "Gene",
   "HGNC_trans_name" => "Transcript"
  );

  foreach my $source (keys %check_type) {
    my $object_type = $check_type{$source};
    my $table = lc($object_type);

    my $desc_1 = "All $source xrefs assigned to ${object_type}s";
    my $sql_1  = qq/
      SELECT COUNT(*) FROM
        object_xref ox INNER JOIN
        xref USING (xref_id) INNER JOIN
        external_db e USING (external_db_id)
      WHERE
        e.db_name = '$source' AND
        ox.ensembl_object_type <> '$object_type'
    /;

    is_rows_zero($self->dba, $sql_1, $desc_1);
  }
}

1;
