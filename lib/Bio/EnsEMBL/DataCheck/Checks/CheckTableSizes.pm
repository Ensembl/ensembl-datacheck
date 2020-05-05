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

package Bio::EnsEMBL::DataCheck::Checks::CheckTableSizes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckTableSizes',
  DESCRIPTION    => 'Tables must be populated and not differ significantly in row numbers',
  GROUPS         => ['compara'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['compara'],
};

sub tests {
  my ($self) = @_;
  
  my $curr_dba = $self->dba;
  my $curr_helper = $curr_dba->dbc->sql_helper;
  my $prev_dba = $self->get_old_dba;
  my $prev_helper = $prev_dba->dbc->sql_helper;
  
  my $table_sql = "SHOW TABLES";
  my $curr_tables = $curr_helper->execute_simple( -SQL => $table_sql );
  my $prev_tables = $prev_helper->execute_simple( -SQL => $table_sql );
  my $curr_db_name = $curr_dba->dbc->dbname;
  my $prev_db_name = $prev_dba->dbc->dbname;
  
  my %prev_tables = ();
  foreach my $table ( @$prev_tables ) {
    $prev_tables{$table}++;
  }
  my %curr_tables = ();
  foreach my $table ( @$curr_tables ) {
    $curr_tables{$table}++;
  }

  # Tables that are not expected to grow
  my @constant_tables = qw(method_link species_tree_root species_set_tag);
  my $division = $curr_dba->get_division();
  if ($division eq 'pan') {
    # The number of species in pan is frozen
    push @constant_tables, qw(genome_db method_link_species_set species_set species_set_header);
  }
  my %constant_tables = map {$_ => 1} @constant_tables;
  
  foreach my $table ( @$curr_tables ) {

    # The meta table is not expected to follow the same growth rules
    next if $table eq 'meta';

    my $desc_1 = "The number of rows in $table for $curr_db_name has not increased by >10% from $prev_db_name";
    my $desc_2 = "The number of rows in $table for $curr_db_name has not decreased by >5% from $prev_db_name";
    my $desc_3 = "The number of rows in $table has changed between $curr_db_name and $prev_db_name";
    my $desc_5 = "Table $table has the same number of rows as in $prev_db_name";
    my $desc_6 = "Table $table is still empty";
    my $desc_7 = "Table $table is still not empty";
    my $sql = qq/
      SELECT COUNT(*) FROM $table
    /;
      
    if ( exists($prev_tables{$table}) ) {
      my $prev_row_count = $prev_helper->execute_single_result( -SQL => $sql );
      my $curr_row_count = $curr_helper->execute_single_result( -SQL => $sql );

      if ($constant_tables{$table}) {
        # Tables that should have a constant size
        is($curr_row_count, $prev_row_count, $desc_5);

      } elsif ($prev_row_count) {
        # Non empty tables should remain not empty
        isnt( $curr_row_count, 0, $desc_7);

        # Don't bother doing these tests since we know they will fail and
        # the reason has already been reported
        if ($curr_row_count) {
          # Both tables have some data, we expect the new size to be
          # different and within the [95%, 110%] interval
          cmp_ok( $curr_row_count, '<=', ($prev_row_count*1.1), $desc_1 );
          cmp_ok( $curr_row_count, '>=', ($prev_row_count*0.95), $desc_2 );
          isnt( $curr_row_count, $prev_row_count, $desc_3 );
        }

      } else {
        # Empty tables should remain empty
        is($curr_row_count, 0, $desc_6);
      }
        
    } else {
      my $desc_4 = "New table: $table is populated with data";
      is_rows_nonzero($curr_dba->dbc, $sql, $desc_4);
    }
  }
  
  foreach my $table ( @$prev_tables ) {
    my $desc_5 = "Table $table is still present in $curr_db_name (was present in $prev_db_name)";
    ok( exists($curr_tables{$table}), $desc_5 );
  }
}

1;
