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

package Bio::EnsEMBL::DataCheck::Checks::UniqueKeysCompara;

use warnings;
use strict;

use Moose;
use Path::Tiny;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/repo_location/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'UniqueKeysCompara',
  DESCRIPTION => 'Unique key relationships are not violated',
  GROUPS      => ['compara', 'compara_gene_trees', 'compara_genome_alignments', 'compara_master', 'compara_syntenies'],
  DB_TYPES    => ['compara'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  my $table_sql_file = $self->table_sql_file();

  my @failed_to_parse;

  my $table;
  foreach my $line ( path($table_sql_file)->lines ) {
    if ($line =~ /CREATE TABLE (IF NOT EXISTS )?`?(\w+)`?/) {
      $table = $2;
    } elsif (defined $table) {
      next if $line =~ /^\-\-/;
      next unless $line =~ /\bUNIQUE\b/;

      $line =~ s/\(\d+\)//g;
      my ($dum1, $dum2, $cols) = $line =~
        /\s*UNIQUE\s+(KEY\s+)?([^\(]+)?\(([^)]+)\)/i;
      if (defined $cols) {
          # We merely host the "external_db" table, we don't manage it ourselves
          next if $table eq 'external_db';
          $self->unique($table, $cols);
      } else {
        push @failed_to_parse, $line;
      }
    }
  }

  my $desc_parsed = "Parsed all unique key relationships from file";
  is(scalar(@failed_to_parse), 0, $desc_parsed) ||
    diag explain @failed_to_parse;
}

sub table_sql_file {
  my ($self) = @_;

  # Don't need checking here, the DB_TYPES ensure we won't get
  # a $dba from a group that we can't handle, and the repo_location
  # method will die if the repo path isn't visible to Perl.
  my $repo_location  = repo_location($self->dba->group);
  my $table_sql_file = "$repo_location/sql/table.sql";

  if (! -e $table_sql_file) {
    die "Table file does not exist: $table_sql_file";
  }

  return $table_sql_file;
}


sub unique {
  my ($self, $table, $cols) = @_;
  # When the key comprises a single column, NULLs are ignored and the
  # unicity is assessed on the non-NULL values only
  # When the key comprises multiple columns, NULLs are kept and count
  # towards considering the rows equal (unlike the default SQL behaviour)
  my $sql = $cols =~ /,/
            ? "SELECT $cols FROM $table GROUP BY $cols HAVING COUNT(*) > 1"
            : "SELECT $cols FROM $table WHERE $cols IS NOT NULL GROUP BY $cols HAVING COUNT(*) > 1";
  my $desc = "The columns ($cols) form a unique key in $table";
  is_rows_zero($self->dba, $sql, $desc);
}

1;
