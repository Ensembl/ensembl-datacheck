=head1 LICENSE
Copyright [2018] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 NAME

Bio::EnsEMBL::DataCheck::Utils

=head1 DESCRIPTION

General purpose functions for datachecks.

=cut

package Bio::EnsEMBL::DataCheck::Utils;

use strict;
use warnings;
use feature 'say';

require Exporter;
our @ISA       = qw( Exporter );
our @EXPORT_OK = qw( repo_location sql_count array_diff hash_diff );

use File::Spec::Functions qw/catdir splitdir/;

=head2 Utility functions

=over 4

=item B<repo_location>

repo_location($repo_name_or_dbtype);

Finds the path to an Ensembl repository in your Perl environment.
The C<$repo_name_or_dbtype> parameter can be either the repository name
or a database type. E.g. C<repo_location('ensembl-variation')> and
C<repo_location('variation')> are equivalent, and will return something like
C</homes/superstar/work/repositories/ensembl-variation>.

=cut

sub repo_location {
  my ($repo_name_or_dbtype) = @_;

  my $repo_name;
  my %repo_names = (
    'cdna'          => 'ensembl',
    'compara'       => 'ensembl-compara',
    'core'          => 'ensembl',
    'funcgen'       => 'ensembl-funcgen',
    'otherfeatures' => 'ensembl',
    'production'    => 'ensembl-production',
    'rnaseq'        => 'ensembl',
    'variation'     => 'ensembl-variation',
  );
  if (exists $repo_names{$repo_name_or_dbtype}) {
    $repo_name = $repo_names{$repo_name_or_dbtype};
  } else {
    $repo_name = $repo_name_or_dbtype;
  }

  foreach my $location (@INC) {
    my @dirs = splitdir($location);
    if (scalar(@dirs) >= 2) {
      if ($dirs[-2] eq $repo_name) {
        pop @dirs;
        return catdir(@dirs);
      }
    }
  }

  die "$repo_name was not found in \@INC:\n" . join("\n", @INC);
}

=item B<sql_count>

sql_count($dbc, $sql, $params);

This runs an SQL statement C<$sql> against the database connection C<$dbc>.
An arrayref of parameters specified via C<$params> are substituted in for '?'
symbols inthe SQL statement in the usual DBI-ish way. The SQL statement can
be an explicit C<COUNT(*)> (recommended for speed) or a C<SELECT> statement
whose rows will be counted. The database connection can be a
Bio::EnsEMBL::DBSQL::DBConnection or DBAdaptor object.

=back

=cut

sub sql_count {
  my ($dbc, $sql, $params) = @_;

  $dbc = $dbc->dbc() if $dbc->can('dbc');

  if ($sql =~ /^\s*SELECT COUNT/i && $sql !~ /GROUP BY/i) {
    return $dbc->sql_helper->execute_single_result(-SQL => $sql, -PARAMS => $params);
  } else {
    return scalar @{ $dbc->sql_helper->execute(-SQL => $sql, -PARAMS => $params) };
  }
}

=over 4

=item B<array_diff>

array_diff($array_1, $array_2, [$array_1_label, [$array_2_label]]);

Calculate the difference between two arrays of string values, C<$array_1>
and C<$array_1>, ignoring the order of the elements.
This method B<does not> work with elements that are references.
The C<$array_1_label> and C<$array_2_label> parameters allow elements
that are only in one array to be usefully labelled in the results.

The return value is two element hash, the values of which are arrays of
elements that are only present in one array. This returned hash is perfect
for passing to C<diag explain> upon the failure of a test
(probably C<is_deeply>), in order to provide complete diagnostics. 

=cut

sub array_diff {
  my ($array_1, $array_2, $array_1_label, $array_2_label) = @_;

  my @array_1_only;
  my @array_2_only;

  my %array_1 = map { $_ => 1 } @$array_1; 
  my %array_2 = map { $_ => 1 } @$array_2; 

  foreach my $key (sort keys %array_1) {
    unless (exists $array_2{$key}) {
      push @array_1_only, $key;
    }
  }

  foreach my $key (sort keys %array_2) {
    unless (exists $array_1{$key}) {
      push @array_2_only, $key;
    }
  }

  $array_1_label = 'first set' unless $array_1_label;
  $array_2_label = 'second set' unless $array_2_label;
  my %diff = (
    "In $array_1_label only" => \@array_1_only,
    "In $array_2_label only" => \@array_2_only,
  );

  return (\%diff);
}

=over 4

=item B<hash_diff>

hash_diff($hash_1, $hash_2, [$hash_1_label, [$hash_2_label]]);

Calculate the difference between two hashes whose values are string values,
C<$hash_1> and C<$hash_2>.
This method B<does not> work with values that are references.
The C<$hash_1_label> and C<$hash_2_label> parameters allow key-value pairs
that are only in one hash to be usefully labelled in the results.

The return value is a hash of three hashes. Two of the subhashes contain
key-value pairs for which the key is only present in one hash or the other.
The third subhash contains key-value pairs where the key exists in both
hashes, but with different values. This returned hash is perfect
for passing to C<diag explain> upon the failure of a test
(probably C<is_deeply>), in order to provide complete diagnostics. 

=cut

sub hash_diff {
  my ($hash_1, $hash_2, $hash_1_label, $hash_2_label) = @_;

  my %hash_1_only;
  my %hash_2_only;
  my %different_values;

  foreach my $key (keys %$hash_1) {
    if (exists $$hash_2{$key}) {
      if ($$hash_1{$key} ne $$hash_2{$key}) {
        $different_values{$key} = [$$hash_1{$key}, $$hash_2{$key}];
      }
    } else {
      $hash_1_only{$key} = $$hash_1{$key};
    }
  }

  foreach my $key (keys %$hash_2) {
    unless (exists $$hash_1{$key}) {
      $hash_2_only{$key} = $$hash_2{$key};
    }
  }

  $hash_1_label = 'first set' unless $hash_1_label;
  $hash_2_label = 'second set' unless $hash_2_label;
  my %diff = (
    "In $hash_1_label only" => \%hash_1_only,
    "In $hash_2_label only" => \%hash_2_only,
    'Different values'      => \%different_values,
  );

  return (\%diff);
}

1;
