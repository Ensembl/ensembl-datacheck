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

package Bio::EnsEMBL::DataCheck::Checks::CompareVariationSources;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareVariationSources',
  DESCRIPTION    => 'Compare variation counts between two databases, categorised by source',
  GROUPS         => ['compare_variation'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['variation'],
  TABLES         => ['source', 'variation']
};

sub tests {
  my ($self) = @_;
  
  SKIP: {
    my $old_dba = $self->get_old_dba();

    skip 'No old version of database', 1 unless defined $old_dba;
    
    my $desc_1 = "Consistent variation counts between ".
               $self->dba->dbc->dbname.' and '.$old_dba->dbc->dbname;
    my $sql_1  = 'SELECT COUNT(*) FROM variation';
    row_totals($self->dba, $old_dba, $sql_1, undef, 1.00, $desc_1);
    
    my $desc_2 = "Consistent variation counts by source between ".
               $self->dba->dbc->dbname.' and '.$old_dba->dbc->dbname;
    my $sql_2  = q/
      SELECT s.name, COUNT(*) 
      FROM variation v JOIN source s 
        ON (s.source_id = v.source_id) 
      GROUP BY s.name
    /;
    row_subtotals($self->dba, $old_dba, $sql_2, undef, 1.00, $desc_2);
  }
}

1;
