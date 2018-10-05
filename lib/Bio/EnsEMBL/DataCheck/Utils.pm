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
our @EXPORT_OK = qw( repo_location sql_count );

use File::Spec::Functions qw/catdir splitdir/;

=head2 Utility functions

=over 4

=item B<repo_location>

repo_location($repo_name);

Finds the path to an Ensembl repository C<$repo_name> in your Perl environment.
E.g. C<repo_location(ensembl-variation)> might return
C</homes/superstar/work/repositories/ensembl-variation>.

=cut

sub repo_location {
  my ($repo_name) = @_;

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

  if ($sql =~ /^SELECT COUNT/i && $sql !~ /GROUP BY/i) {
    return $dbc->sql_helper->execute_single_result(-SQL => $sql, -PARAMS => $params);
  } else {
    return scalar @{ $dbc->sql_helper->execute(-SQL => $sql, -PARAMS => $params) };
  }
}

1;
