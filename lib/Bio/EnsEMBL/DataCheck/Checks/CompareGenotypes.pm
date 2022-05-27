=head1 LICENSE

Copyright [2018-2022] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CompareGenotypes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareGenotypes',
  DESCRIPTION    => 'Compare genotype counts between two databases',
  GROUPS         => ['compare_variation'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['variation'],
  TABLES         => ['compressed_genotype_region', 'compressed_genotype_var', 'population_genotype']
};

sub tests {
  my ($self) = @_;
  
  SKIP: {
    my $old_dba = $self->get_old_dba();

    skip 'No old version of database', 1 unless defined $old_dba;

    my $desc_1 = "Consistent population_genotype counts between ".
               $self->dba->dbc->dbname.' and '.$old_dba->dbc->dbname;
    my $sql_1  = 'SELECT COUNT(*) FROM population_genotype';
    row_totals($self->dba, $old_dba, $sql_1, undef, 1.00, $desc_1);
    
    my $desc_2 = "Consistent compressed_genotype_region counts between ".
               $self->dba->dbc->dbname.' and '.$old_dba->dbc->dbname;
    my $sql_2  = 'SELECT COUNT(*) FROM compressed_genotype_region';
    row_totals($self->dba, $old_dba, $sql_2, undef, 1.00, $desc_2);
    
    my $desc_3 = "Consistent compressed_genotype_var between ".
               $self->dba->dbc->dbname.' and '.$old_dba->dbc->dbname;
    my $sql_3  = 'SELECT COUNT(*) FROM compressed_genotype_var';
    row_totals($self->dba, $old_dba, $sql_3, undef, 1.00, $desc_3);
  }
}

1;
