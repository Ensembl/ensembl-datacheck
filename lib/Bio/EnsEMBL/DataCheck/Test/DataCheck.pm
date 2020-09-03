=head1 LICENSE

Copyright [2018-2020] EMBL-European Bioinformatics Institute

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

=head1 NAME

Bio::EnsEMBL::DataCheck::Test::DataCheck

=head1 DESCRIPTION

Collection of Test::More style tests for Ensembl data.

=cut

package Bio::EnsEMBL::DataCheck::Test::DataCheck;

use warnings;
use strict;
use feature 'say';

use Test::Builder::Module;

our $VERSION = 1.00;
our @ISA     = qw(Test::Builder::Module);
our @EXPORT  = qw(
  is_rows cmp_rows is_rows_zero is_rows_nonzero
  row_totals row_subtotals
  fk denormalized denormalised
  has_data
  is_one_to_many
);

use constant MAX_DIAG_ROWS => 10;

my $CLASS = __PACKAGE__;

sub _query {
  my ( $dbc, $sql ) = @_;

  $dbc = $dbc->dbc() if $dbc->can('dbc');

  my ($count, $rows);

  if ($sql =~ /^\s*SELECT COUNT/i && $sql !~ /GROUP BY/i) {
    $count = $dbc->sql_helper()->execute_single_result( -SQL => $sql );
  } else {
    $rows  = $dbc->sql_helper()->execute( -SQL => $sql );
    $count = scalar @$rows;
  }

  return ($count, $rows);
}

=head2 Counting Database Rows

Tests for counting rows are among the most basic (and most useful) ways
to check whether data is as expected.

=over 4

=item B<is_rows>

is_rows($dbc, $sql, $expected, $test_name);

This runs an SQL statement C<$sql> against the database connection C<$dbc>.
If the number of rows matches C<$expected>, the test will pass. The SQL
statement can be an explicit C<COUNT(*)> (recommended for speed) or a
C<SELECT> statement whose rows will be counted. The database connection
can be a Bio::EnsEMBL::DBSQL::DBConnection or DBAdaptor object.

C<$test_name> is a very short description of the test that will be printed
out; it is optional, but we B<very> strongly encourage its use.

=cut

sub is_rows {
  my ( $dbc, $sql, $expected, $name ) = @_;

  my $tb = $CLASS->builder;

  my ( $count, undef ) = _query( $dbc, $sql );

  return $tb->is_eq( $count, $expected, $name );
}

=item B<cmp_rows>

cmp_rows($dbc, $sql, $operator, $expected, $test_name);

This runs an SQL statement C<$sql> against the database connection C<$dbc>.
If the number of rows is C<$operator $expected>, the test will pass. The
operator can be any valid Perl operator, e.g. '<', '!='. The SQL
statement can be an explicit C<COUNT(*)> (recommended for speed) or a
C<SELECT> statement whose rows will be counted. The database connection
can be a Bio::EnsEMBL::DBSQL::DBConnection or DBAdaptor object.

C<$test_name> is a very short description of the test that will be printed
out; it is optional, but we B<very> strongly encourage its use.

=cut

sub cmp_rows {
  my ( $dbc, $sql, $operator, $expected, $name ) = @_;

  my $tb = $CLASS->builder;

  my ( $count, undef ) = _query( $dbc, $sql );

  return $tb->cmp_ok( $count, $operator, $expected, $name );
}

=item B<is_rows_zero>

is_rows_zero($dbc, $sql, $test_name, $diag_msg);

This runs an SQL statement C<$sql> against the database connection C<$dbc>.
If the number of rows is zero, the test will pass. The SQL statement can be
an explicit C<COUNT(*)> or a C<SELECT> statement whose rows will be counted.
In the latter case, rows which are returned will be printed as diagnostic
messages; we strongly advise providing a meaningful C<$diag_msg>, otherwise
a generic one will be displayed. A maximum of 10 messages will be displayed
The database connection can be a Bio::EnsEMBL::DBSQL::DBConnection or
DBAdaptor object.

C<$test_name> is a very short description of the test that will be printed
out; it is optional, but we B<very> strongly encourage its use.

=cut

sub is_rows_zero {
  my ( $dbc, $sql, $name, $diag_msg ) = @_;

  my $tb = $CLASS->builder;

  my ( $count, $rows ) = _query( $dbc, $sql );

  my $result = $tb->is_eq( $count, 0, $name );

  if (defined $rows) {
    if (!defined $diag_msg) {
      $diag_msg = "Unexpected data";
    }

    my ($columns) = $sql =~ /SELECT(?: DISTINCT)? (.*)\s+FROM/m;
    if ($columns && $columns ne '*') {
      $diag_msg .= ": (".$columns.") =";
    }

    my $counter = 0;
    foreach my $row ( @$rows ) {
      for ( @$row ) { $_ = 'NULL' unless defined $_; }
      $tb->diag( "$diag_msg (" . join(', ', @$row) . ")" );
      last if ++$counter == MAX_DIAG_ROWS;
    }

    $dbc = $dbc->dbc() if $dbc->can('dbc');
    my $dbname = $dbc->dbname;

    if ($count > MAX_DIAG_ROWS) {
      $tb->diag( 'Reached limit for number of diagnostic messages' );
      $tb->diag( "Execute $sql against $dbname to see all results" );
    } elsif ($count > 0) {
      $tb->diag( "Execute $sql against $dbname to replicate these results" );
    }
  }

  return $result;
}

=item B<is_rows_nonzero>

is_rows_nonzero($dbc, $sql, $test_name);

Convenience method, equivalent to cmp_rows($dbc, $sql, '>', 0, $test_name).

=back

=cut

sub is_rows_nonzero {
  my ( $dbc, $sql, $name ) = @_;

  my $tb = $CLASS->builder;

  my ( $count, undef ) = _query( $dbc, $sql );

  return $tb->cmp_ok( $count, '>', 0, $name );
}

=head2 Comparing Database Rows

=over 4

=item B<row_totals>

=item B<row_subtotals>

Rather than compare a row count with an expected value, we might want to
compare with a count from another database. The simplest scenario is when
there's a single total to compare.

row_totals($dbc1, $dbc2, $sql1, $sql2, $min_proportion, $test_name);

This runs an SQL statement C<$sql1> against database connection C<$dbc1>,
and C<$sql2> against C<$dbc2>. In most cases one of these parameters will
be undefined: if C<$dbc2> is undefined, then both SQL statements will be
executed against C<$dbc1>; if C<$sql2> is undefined, then C<$sql1> will
be run against both database connections.

The SQL statements can have an explicit C<COUNT(*)> (recommended
for speed) or can be a C<SELECT> statement whose rows will be counted.
The database connections can be a Bio::EnsEMBL::DBSQL::DBConnection or
DBAdaptor object. It is assumed that C<$dbc1> is the connection for a new or
'primary' database, and that C<$dbc2> is for an old, or 'secondary' database.

By default, the test only passes if the counts are exactly the same. To allow
for some wiggle room, C<$min_proportion> can be used to define the minimum
acceptable difference between the counts. For example, a value of 0.75 means
that the count for C<$dbc1> must not be less than 75% of the count for C<$dbc2>.
If two SQL statements are given, a value of 0.75 means that the count for
C<$sql1> must not be less than 75% of the count for C<$sql2>.

C<$test_name> is a very short description of the test that will be printed
out; it is optional, but we B<very> strongly encourage its use.

A slightly more complex case is when you want to compare counts within
categories, i.e. with an SQL query that uses a GROUP BY statement.

row_subtotals($dbc1, $dbc2, $sql1, $sql2, $min_proportion, $test_name);

In this case the SQL statements must return only two columns, the subtotal
category and the count, e.g. C<SELECT biotype, COUNT(*) FROM gene GROUP BY biotype>.
If any subtotals are lower than expected the test will fail, and the details
will be provided in a diagnostic message.

=back

=cut

sub row_totals {
  my ( $dbc1, $dbc2, $sql1, $sql2, $min_proportion, $name ) = @_;

  my $tb = $CLASS->builder;

  $dbc2 = $dbc1 if ! defined $dbc2;
  $sql2 = $sql1 if ! defined $sql2;

  my ( $count1, undef ) = _query( $dbc1, $sql1 );
  my ( $count2, undef ) = _query( $dbc2, $sql2 );

  if (defined $min_proportion) {
    return $tb->cmp_ok( $count2 * $min_proportion, '<=', $count1, $name );
  } else {
    return $tb->is_eq( $count2, $count1, $name );
  }
}

sub row_subtotals {
  my ( $dbc1, $dbc2, $sql1, $sql2, $min_proportion, $name ) = @_;

  my $tb = $CLASS->builder;

  $dbc2 = $dbc1 if ! defined $dbc2;
  $sql2 = $sql1 if ! defined $sql2;
  $min_proportion = 1 if ! defined $min_proportion;

  my ( undef, $rows1 ) = _query( $dbc1, $sql1 );
  my ( undef, $rows2 ) = _query( $dbc2, $sql2 );

  if (not defined $rows1) {
    die "Invalid SQL query for row_subtotals.\n($sql1)";
  };

  if (not defined $rows2) {
    die "Invalid SQL query for row_subtotals.\n($sql2)";
  };

  my $len1 = @$rows1;
  my $len2 = @$rows2;

  if ($len1 > 0) {
    my $len_elem1 = @{$$rows1[0]};
    if ($len_elem1 != 2) {
      die "Invalid SQL query for row_subtotals. Must return exactly two columns, a key and a number.\n($sql1)"
    }
    else {
      my $count1 = $$rows1[0][1];
      die "Invalid SQL query for row_subtotal. Second column must be a number.\n($sql1)" unless $count1 =~ /^[0-9]+$/;
    }
  }
  if ($len2 > 0) {
    my $len_elem2 = @{$$rows2[0]};
    if ($len_elem2 != 2) {
      die "Invalid SQL query for row_subtotals. Must return exactly two columns, a key and a number.\n($sql2)"
    }
    else {
      my $count2 = $$rows2[0][1];
      die "Invalid SQL query for row_subtotals. Second column must be a number.\n($sql2)" unless $count2 =~ /^[0-9]+$/;
    }
  }

  my %subtotals1 = map { $_->[0] => $_->[1] } @$rows1;
  my %subtotals2 = map { $_->[0] => $_->[1] } @$rows2;

  my @diag_msgs;

  # Note that there may be categories in %subtotals1 that aren't in
  # %subtotals2; that's usually not an issue, but if that's important
  # the test can be called again with dbc/sql parameters flipped.
  foreach my $category (keys %subtotals2) {
    $subtotals1{$category} = 0 unless exists $subtotals1{$category};

    if (defined $min_proportion) {
      if ($subtotals2{$category} * $min_proportion > $subtotals1{$category}) {
        my $diag_msg =
          "Lower count than expected for $category.\n".
          $subtotals1{$category} . ' < ' . $subtotals2{$category} . ' * ' . $min_proportion*100 . '%';
        push @diag_msgs, $diag_msg;
      }
    } else {
      if ($subtotals2{$category} != $subtotals1{$category}) {
        my $diag_msg =
          "Counts do not match for $category.\n".
          $subtotals1{$category} . ' != ' . $subtotals2{$category};
        push @diag_msgs, $diag_msg;
      }
    }
  }

  my $ok = scalar(@diag_msgs) ? 0 : 1;
  $tb->ok( $ok, $name );
  foreach my $diag_msg (@diag_msgs) {
    $tb->diag( $diag_msg );
  }

  return $ok;
}

=head2 Testing Referential Integrity

=over 4

=item B<fk>

Referential integrity is not enforced by the MyISAM tables that we
currently use. InnoDB might come in to play in the future, but for
now it needs to be checked.

fk($dbc, $table1, $col1, $table2, $col2, $constraint, $test_name);

For the database connection C<$dbc> this checks that every instance of
C<$table1.$col1> exists in C<$table2.$col2>, i.e. there are no "orphan"
rows in C<$table1>. Note that the reciprocal is not done automatically;
if you also want to check that every instance of C<$table2.$col2> exists
in C<$table1.$col1>, you'll need to call the function again.

An optional C<$constraint> can be provided to restrict the rows that
are checked.

C<$test_name> is a very short description of the test that will be printed
out; if not provided, a descriptive name will be generated.

=back

=cut

sub fk {
  my ( $dbc, $table1, $col1, $table2, $col2, $constraint, $name ) =  @_;

  my $tb = $CLASS->builder;

  $col2 = $col1 unless defined $col2;
  $name = "All $table1.$col1 rows linked to $table2.$col2 rows" unless defined $name;

  my $sql = qq/
    SELECT COUNT(*) FROM
    $table1 t1 LEFT JOIN $table2 t2 ON t1.$col1 = t2.$col2
    WHERE t1.$col1 IS NOT NULL AND t2.$col2 IS NULL
  /;
  $sql .= " AND $constraint" if $constraint;

  my ( $count, undef ) = _query( $dbc, $sql );
  my $result = $tb->is_eq( $count, 0, $name );

  if ( $count > 0 ) {
    my $diag_msg = "Broken referential integrity found with SQL: $sql";
    $tb->diag( $diag_msg );
  }

  return $result;
}

=head2 Testing Denormalization

=over 4

=item B<denormalized>

Some databases are denormalized in order to speed up queries. This
function checks whether the values in two tables are synchronized.

denormalized($dbc, $table1, $col1a, $col1b $table2, $col2a, $col2b, $test_name);

For the database connection C<$dbc> this joins on C<$table1.$col1a> and
C<$table2.$col2a>, then checks that C<$table1.$col1b> = C<$table2.$col2b>.

C<$test_name> is a very short description of the test that will be printed
out; if not provided, a descriptive name will be generated.

=back

=cut

sub denormalized {
  my ( $dbc, $table1, $col1a, $col1b, $table2, $col2a, $col2b, $name ) =  @_;

  my $tb = $CLASS->builder;

  $col2a = $col1a unless defined $col2a;
  $col2b = $col1b unless defined $col2b;
  $name = "All $table1.$col1b rows in sync with $table2.$col2b" unless defined $name;

  my $sql = qq/
    SELECT COUNT(*) FROM
    $table1 t1 INNER JOIN $table2 t2 ON t1.$col1a = t2.$col2a
    WHERE t1.$col1b <> t2.$col2b
  /;

  my ( $count, undef ) = _query( $dbc, $sql );
  my $result = $tb->is_eq( $count, 0, $name );

  if ( $count > 0 ) {
    my $diag_msg = "Faulty denormalisation found with SQL: $sql";
    $tb->diag( $diag_msg );
  }

  return $result;
}

sub denormalised {
  return denormalized(@_);
}

=head2 Testing Database Columns

=over 4

=item B<has_data>

has_data($dbc, $table, $column, $id, $test_name, $diag_msg);

Tests if the C<$column> in C<$table> has null or blank values.
If all the rows have a non-NULL, non-blank value, the test will pass.
The C<$id> parameter should be a column name that will be useful for
diagnostics in the case of failure (typically this would be something
that uniquely identifies a row, such as an auto-incremented ID).

=back

=cut

sub has_data {
  my ($dbc, $table, $column, $id, $test_name, $diag_msg) = @_;

  my $sql = qq/
    SELECT $id
    FROM $table
    WHERE $column IS NULL
    OR $column = 'NULL'
    OR $column = ''
  /;

  is_rows_zero($dbc, $sql, $test_name, $diag_msg);
}

=head2 Testing one-to-many relationships

=over 4

=item B<is_one_to_many>

is_one_to_many($dbc, $table, $column, $test_name, $constraint);

Tests that each C<$column> member is present in the table more than once.
If all the rows have a count>1, the test will pass. C<$constraint> is an optional
SQL where clause.

=back

=cut

sub is_one_to_many {
  my ($dbc, $table, $column, $test_name, $constraint) = @_;

  if (!defined $constraint) {
    $constraint = "";
  }
  elsif ($constraint !~ /WHERE/) {
    $constraint = "WHERE $constraint";
  }

  my $sql = qq/
    SELECT $column
    FROM $table
    $constraint
    GROUP BY $column
    HAVING COUNT(*) = 1
  /;

  is_rows_zero($dbc, $sql, $test_name);
}

1;
