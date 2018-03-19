
=head1 LICENSE

Copyright [2016] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

  Questions may also be sent to the Ensembl help desk at
  <http://www.ensembl.org/Help/Contact>.

=cut

=head1 NAME

Bio::EnsEMBL::DataCheck::Utils::DBUtils

=head1 SYNOPSIS

is_rowcount($dba, "select count(*) from gene where biotype='mango'", 100, 
  "We need 100 mangoes");
is_rowcount_zero($dba, "select count(*) from gene where biotype='banana'", 
  "Yes, we have no bananas");
is_same_counts($dba, $dba2, "select biotype,count(*) from gene group by biotype",
  1,"Checking for the same number of biotypes");

=head1 DESCRIPTION

Collection of utilities for testing Ensembl MySQL databases, including a set of 
Test::More style tests.

=head1 METHODS

=cut

package Bio::EnsEMBL::DataCheck::Utils::DBUtils;
use warnings;
use strict;
use Carp qw/croak/;

use Test::More;

BEGIN {
  require Exporter;
  our $VERSION = 1.00;
  our @ISA     = qw(Exporter);
  our @EXPORT =
    qw(rowcount is_rowcount is_rowcount_zero is_rowcount_nonzero
    ok_foreignkeys get_species_ids is_query is_same_counts is_same_result);
}

=head2 get_species_ids

  Arg [1]    : Bio::EnsEMBL::DBSQL::DBConnection or DBAdaptor
  Example    : my $sids = get_species_ids($dbc);
  Description: Get species_ids for a core database
  Returntype : Arrayref of integers
  Exceptions : None
  Caller     : general
  Status     : Stable

=cut

sub get_species_ids {
  my ($dbc) = @_;
  if ( $dbc->can('dbc') ) {
    $dbc = $dbc->dbc();
  }
  return $dbc->sql_helper()
    ->execute( -SQL =>
          'select distinct species_id from meta where species_id is not null' );
}

=head2 rowcount

  Arg [1]    : Bio::EnsEMBL::DBSQL::DBConnection or DBAdaptor
  Arg [2]    : SQL to run
  Example    : my $cnt = rowcount($dba,"select count(*) from gene")
  Description: Return the number of rows in a query 
               (can be any query though count(*) is faster)
  Returntype : integer
  Exceptions : None
  Caller     : general
  Status     : Stable

=cut

sub rowcount {
  my ( $dbc, $sql ) = @_;
  if ( $dbc->can('dbc') ) {
    $dbc = $dbc->dbc();
  }
  #diag($sql);
  if ( index( uc($sql), "SELECT COUNT" ) != -1 &&
       index( uc($sql), "GROUP BY" ) == -1 )
  {
    return $dbc->sql_helper()->execute_single_result( -SQL => $sql );
  }
  else {
    return scalar @{ $dbc->sql_helper()->execute( -SQL => $sql ) };
  }
}

=head2 is_rowcount

  Arg [1]    : Bio::EnsEMBL::DBSQL::DBConnection or DBAdaptor
  Arg [2]    : SQL to test
  Arg [3]    : Expected rowcount
  Arg [4]    : Optional name for test
  Example    : is_rowcount($dba,"select count(*) from gene",100,
                 "test for 100 genes")
  Description: Test to see if the expected number of rows is returned
  Returntype : none
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub is_rowcount {
  my ( $dba, $sql, $expected, $name ) = @_;
  $name ||= "Checking that $sql returns $expected";
  is( rowcount( $dba, $sql ), $expected, $name );
  return;
}

=head2 is_rowcount_zero

  Arg [1]    : Bio::EnsEMBL::DBSQL::DBConnection or DBAdaptor
  Arg [2]    : SQL to test
  Arg [3]    : Optional name for test
  Example    : is_rowcount_zero($dba,"select count(*) from operon",
                 "Test to make sure we have no operons)
  Description: Test whether the supplied query returns 0 rows
  Returntype : none
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub is_rowcount_zero {
  my ( $dba, $sql, $name ) = @_;
  is_rowcount( $dba, $sql, 0, $name );
  return;
}

=head2 is_rowcount_nonzero

  Arg [1]    : Bio::EnsEMBL::DBSQL::DBConnection or DBAdaptor
  Arg [2]    : SQL to test
  Arg [3]    : Optional name for test
  Example    : is_rowcount_nonzero($dba,"select count(*) from operon",
                 "Test to make sure we have operons)
  Description: Test whether the supplied query returns more than 0 rows
  Returntype : none
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub is_rowcount_nonzero {
  my ( $dba, $sql, $name ) = @_;
  ok( rowcount( $dba, $sql ) > 0, $name );
  return;
}

=head2 is_query

  Arg [1]    : Bio::EnsEMBL::DBSQL::DBConnection or DBAdaptor
  Arg [2]    : Expected value
  Arg [3]    : SQL to test
  Arg [4]    : Optional name for test
  Example    : is_query($dba,
                 "select meta_value from meta where meta_key='species.production_name'",
                 "homo_sapiens","Are we human?");
  Description: Test whether the supplied query returns an expected value
  Returntype : none
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub is_query {
  my ( $dba, $expected, $sql, $name ) = @_;
  is( $expected,
      $dba->dbc()->sql_helper()->execute_single_result( -SQL => $sql ), $name );
  return;
}

=head2 is_same_result

  Arg [1]    : Bio::EnsEMBL::DBSQL::DBConnection or DBAdaptor
  Arg [2]    : Bio::EnsEMBL::DBSQL::DBConnection or DBAdaptor
  Arg [3]    : SQL to test
  Arg [4]    : Optional name for test
  Example    : is_same_result($dba,$dba2,
                "select species_id,meta_value from meta where meta_key='species.classification'",
                "Compare classification");
  Description: Compare results of SQL on 2 databases
  Returntype : none
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub is_same_result {
  my ( $dba, $dba2, $sql, $name ) = @_;
  $name ||= "Comparing results of $sql";
  my $r1 = $dba->dbc()->sql_helper()->execute( -SQL => $sql );
  my $r2 = $dba2->dbc()->sql_helper()->execute( -SQL => $sql );
  if ( scalar(@$r1) != scalar(@$r2) ) {
    fail( $name . " - different row counts" );
  }
  else {
    for ( my $i = 0; $i < scalar(@$r1); $i++ ) {
      for ( my $j = 0; $j < scalar( @{ $r1->[$i] } ); $j++ ) {
        is( $r1->[$i]->[$j], $r1->[$i]->[$j], $name . " row $i, column $j" );
      }
    }
  }
  return;
}

=head2 is_same_counts

  Arg [1]    : Bio::EnsEMBL::DBSQL::DBConnection or DBAdaptor ("new")
  Arg [2]    : Bio::EnsEMBL::DBSQL::DBConnection or DBAdaptor ("old")
  Arg [3]    : SQL to test
  Arg [4]    : Optional threshold 
               (e.g. 0.75 allows for new count to be 75% of original)
  Arg [5]    : Optional name for test
  Example    : is_same_counts($new_dba,$old_dba,
                 "select biotype,count(*) from gene group by biotype",0.75,
                 "Test whether biotype counts are still 75% of previous");
  Description: Test whether counts returned by SQL have dropped (within a 
               specified threshold) from an old to a new database instance
  Returntype : none
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub is_same_counts {
  my ( $dba, $dba2, $sql, $threshold, $name ) = @_;
  $threshold ||= 1;
  $name      ||= "Checking counts from $sql";
  my $c1 = $dba->dbc()->sql_helper()->execute_into_hash( -SQL => $sql );
  my $c2 = $dba2->dbc()->sql_helper()->execute_into_hash( -SQL => $sql );
  while ( my ( $k, $v1 ) = each %$c1 ) {
    my $v2 = $c2->{$k} || 0;
    ok( $v1 > ( $v2*$threshold ), $name . " - comparing $k ($v1 vs $v2)" );
  }
  return;
}

=head2 ok_foreignkeys

  Arg [1]    : Bio::EnsEMBL::DBSQL::DBConnection or DBAdaptor
  Arg [2]    : "from" table
  Arg [3]    : "from" column
  Arg [4]    : "to" table
  Arg [5]    : "to" column
  Arg [6]    : (optional) set to 1 to check in both directions
  Arg [7]    : (optional) SQL constraint
  Arg [8]    : (optional) name for test
  Example    : ok_foreignkeys($dba,"gene","canonical_transcript_id",
                 "transcript","transcript_id",0,"",
                 "Check if canonical transcripts exist");
  Description: Check for foreign keys between 2 tables 
  Returntype : none
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub ok_foreignkeys {
  my ( $dba, $table1, $col1, $table2, $col2, $both_ways, $constraint, $name ) =
    @_;

  $col2 ||= $col1;
  $both_ways ||= 0;
  my $sql_left =
    qq/SELECT COUNT(*) FROM $table1 
    LEFT JOIN $table2 ON $table1.$col1 = $table2.$col2 
    WHERE $table2.$col2 IS NULL/;

  if ($constraint) {
    $sql_left .= " AND $constraint";
  }

  is_rowcount_zero( $dba,
                    $sql_left, (
                      $name ||
"Checking for values in ${table1}.${col1} not found in ${table2}.${col2}" ) );

  if ($both_ways) {

    my $sql_right =
      qq/SELECT COUNT(*) FROM $table2 
      LEFT JOIN $table1 
      ON $table2.$col2 = $table1.$col1 
      WHERE $table1.$col1 IS NULL/;

    if ($constraint) {
      $sql_right .= " AND $constraint";
    }

    is_rowcount_zero( $dba,
                      $sql_right, (
                        $name ||
"Checking for values in ${table2}.${col2} not found in ${table1}.${col1}" ) );

  }

  return;
} ## end sub ok_foreignkeys

1;
