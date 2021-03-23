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

=head1 NAME

Bio::EnsEMBL::DataCheck::Test::Compara

=head1 DESCRIPTION

Collection of Test::More style tests for Ensembl compara data.

=cut

package Bio::EnsEMBL::DataCheck::Test::Compara;

use warnings;
use strict;
use feature 'say';

use Test::Builder::Module;


our $VERSION = 1.00;
our @ISA     = qw(Test::Builder::Module);
our @EXPORT  = qw(
  has_tags cmp_tag check_id_range
);

my $CLASS = __PACKAGE__;

=head2 Compara-specific tests

=over 4

=item B<has_tags>

has_tags($dba, $method_link_type, $expected_tags, $test_name);

For each MLSS of type C<$method_link_type>, test whether all of the
C<$expected_tags> exist.

C<$test_name> is a short description of the test that will be printed
out; if not provided, a default will be used.

=cut

sub has_tags {
  my ( $dba, $method_link_type, $expected_tags, $name ) =  @_;

  $name = "All $method_link_type analyses have required tags" unless defined $name;

  my $tb = $CLASS->builder;

  # Don't use a test for every single mlss/tag combo, because there
  # would be a very high number of 'ok's in the output. Collect
  # missing tags as we go, do one test, then report any missing data
  # as diagnostic messages.
  my @diag_msg = ();
  my $mlssa = $dba->get_MethodLinkSpeciesSetAdaptor;

  my $mlss_list = $mlssa->fetch_all_by_method_link_type($method_link_type);
  foreach my $mlss (@$mlss_list) {
    foreach my $tag (@$expected_tags) {
      if (! $mlss->has_tag($tag)) {
        push @diag_msg, "$method_link_type (MLSS ID: ".$mlss->dbID.") lacks tag $tag";
      } elsif (! defined $mlss->get_value_for_tag($tag)) {
        push @diag_msg, "$method_link_type (MLSS ID: ".$mlss->dbID.") tag $tag undefined";
      }
    }
  }
  my $result = $tb->is_eq(scalar(@diag_msg), 0, $name);

  if (scalar(@diag_msg)) {
    # We could limit the number of diagnostic messages,
    # but probably more useful to get a complete set.
    foreach my $row ( @diag_msg ) {
      $tb->diag( $row );
    }
  }

  return $result;
}

=item B<cmp_tag>

cmp_tag($dba, $method_link_type, $tag_name, $operator, $expected, $test_name);

For each MLSS of type C<$method_link_type>, test whether the value
for a given tag is expected.

C<$test_name> is a short description of the test that will be printed
out; if not provided, a default will be used.

=cut

sub cmp_tag {
  my ( $dba, $method_link_type, $tag_name, $operator, $expected, $name ) =  @_;

  $name = "All $method_link_type $tag_name $operator $expected" unless defined $name;

  my $tb = $CLASS->builder;

  # Don't use a test for every single mlss/tag combo, because there
  # would be a very high number of 'ok's in the output. Collect
  # missing tags as we go, do one test, then report any missing data
  # as diagnostic messages.
  my @diag_msg = ();
  my $mlssa = $dba->get_MethodLinkSpeciesSetAdaptor;

  my $mlss_list = $mlssa->fetch_all_by_method_link_type($method_link_type);
  foreach my $mlss (@$mlss_list) {
    my $tag_value = $mlss->get_value_for_tag($tag_name);
    if (defined $tag_value) {
      if ( ! eval("$tag_value $operator $expected") ) {
        push @diag_msg, "$method_link_type (MLSS ID: ".$mlss->dbID.") $tag_name value $tag_value is not $operator $expected";
      }
    } else {
      push @diag_msg, "$method_link_type (MLSS ID: ".$mlss->dbID.") tag $tag_name undefined";
    }
  }
  my $result = $tb->is_eq(scalar(@diag_msg), 0, $name);

  if (scalar(@diag_msg)) {
    # We could limit the number of diagnostic messages,
    # but probably more useful to get a complete set.
    foreach my $row ( @diag_msg ) {
      $tb->diag( $row );
    }
  }

  return $result;
}

=item B<check_id_range>

check_id_range($dba, $table_name, $id_column, $id_column_val, $test_name);

Takes C<$table_name> and $table_name . "_id" in C<$table_name> and checks that
$table_name . "_id" is offset by C<$id_column> using C<$id_column_val>.

This is an offset type commonly used in compara databases using genome_db_id or
method_link_species_set_id for example.

C<$test_name> is a short description of the test that will be printed
out; if not provided, a default will be used.

=back

=cut

sub check_id_range {
  my ($dba, $table_name, $id_column, $id_column_val, $name) = @_;

  my $tb = $CLASS->builder;
  my $helper = $dba->dbc->sql_helper;
  # The naming convention of the id column in table_name follows table_name_id
  my $table_column = $table_name . "_id";
  my $id_length = length($id_column_val);

  my $sql = qq/
    SELECT COUNT(
      DISTINCT(LEFT($table_column, $id_length))
    )
    FROM $table_name
    WHERE $id_column = $id_column_val
  /;

  my $results = $helper->execute_single_result(-SQL => $sql);
  $name = "$table_column in $table_name is correctly offset by $id_column_val" unless defined $name;
  $tb->is_eq( $results, 1, $name );
}

1;
