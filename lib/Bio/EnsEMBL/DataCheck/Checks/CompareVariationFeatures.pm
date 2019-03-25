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

package Bio::EnsEMBL::DataCheck::Checks::CompareVariationFeatures;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareVariationFeatures',
  DESCRIPTION    => 'Compare variation feature counts between two databases, categorised by seq_region name',
  GROUPS         => ['compare_variation'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['variation'],
  TABLES         => ['variation_feature']
};

sub tests {
  my ($self) = @_;

  SKIP: {
    my $old_dba = $self->get_old_dba();

    skip 'No old version of database', 1 unless defined $old_dba;
  
    # Check the assembly version. Skip if not the same
    skip 'Different assemblies', 1 
      unless $self->same_assembly($old_dba->dbc->dbname);
    
    my $desc = "Consistent variation feature counts between ".
               $self->dba->dbc->dbname.' and '.$old_dba->dbc->dbname;

    my ($core_dbname, $old_core_dbname);
    ($core_dbname = $self->dba->dbc->dbname()) =~ s/variation/core/;
    ($old_core_dbname = $old_dba->dbc->dbname()) =~ s/variation/core/;  
        
    my $sql_1 = $self->get_sql($core_dbname);
    my $sql_2 = $self->get_sql($old_core_dbname);
    row_subtotals($self->dba, $old_dba, $sql_1, $sql_2, 1.00, $desc);
  }
}

sub get_sql {
  my ($self, $dbname) = @_;
  my $sql = qq/
    SELECT src.name, COUNT(*) 
    FROM $dbname.seq_region src, $dbname.coord_system cs, variation_feature vf 
    WHERE cs.rank = 1 
      AND cs.coord_system_id = src.coord_system_id 
      AND src.seq_region_id = vf.seq_region_id 
    GROUP BY src.name
  /;
}

sub same_assembly {
    my ($self, $prev_dbname) = @_;
    
    my $curr_assembly = (split(/_/, $self->dba->dbc->dbname))[4];
    my $prev_assembly = (split(/_/, $prev_dbname))[4];
    if ($curr_assembly eq $prev_assembly) {
      return 1;
    } else {
      return 0;
    }
}

1;
