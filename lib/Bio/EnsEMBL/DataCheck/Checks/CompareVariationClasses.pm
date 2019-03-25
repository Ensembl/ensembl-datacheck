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

package Bio::EnsEMBL::DataCheck::Checks::CompareVariationClasses;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareVariationClasses',
  DESCRIPTION    => 'Compare variation counts between two databases, categorised by variation class',
  GROUPS         => ['compare_variation'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['variation'],
  TABLES         => ['attrib', 'variation']
};

sub tests {
  my ($self) = @_;
  
  SKIP: {
    my $old_dba = $self->get_old_dba();

    skip 'No old version of database', 1 unless defined $old_dba;

    my $desc = "Consistent variation class counts between ".
               $self->dba->dbc->dbname.' and '.$old_dba->dbc->dbname;
    my $sql  = q/
      SELECT a.value, COUNT(*) 
      FROM variation v, attrib a 
      WHERE v.class_attrib_id = a.attrib_id 
      GROUP BY a.value
    /;
    row_subtotals($self->dba, $old_dba, $sql, undef, 1.00, $desc);
  }
}

1;
