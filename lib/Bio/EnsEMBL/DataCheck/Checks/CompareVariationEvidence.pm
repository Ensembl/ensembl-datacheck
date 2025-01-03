=head1 LICENSE

Copyright [2018-2025] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CompareVariationEvidence;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareVariationEvidence',
  DESCRIPTION    => 'Compare variation counts between two databases, categorised by evidence',
  GROUPS         => ['compare_variation'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['variation'],
  TABLES         => ['variation','attrib', 'attrib_type']
};

sub tests {
  my ($self) = @_;
  
  SKIP: {
    my $old_dba = $self->get_old_dba();

    skip 'No old version of database', 1 unless defined $old_dba;

    my $desc = "Consistent variation counts by evidence between ".
               $self->dba->dbc->dbname.' and '.$old_dba->dbc->dbname;
    my $sql  = qq/
      SELECT a.attrib_id, COUNT(DISTINCT v.variation_id)
      FROM attrib_type att, attrib a, variation v
      WHERE att.code = 'evidence'
        AND att.attrib_type_id = a.attrib_type_id
        AND FIND_IN_SET(a.attrib_id, v.evidence_attribs)
      GROUP BY a.attrib_id
    /;
    row_subtotals($self->dba, $old_dba, $sql, undef, 0.95, $desc);
  }
}

1;
