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

package Bio::EnsEMBL::DataCheck::Checks::CompareSchema;

use warnings;
use strict;

use Moose;
use Path::Tiny;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/repo_location/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'CompareSchema',
  DESCRIPTION => 'Compare database schema to definition in SQL file',
  GROUPS      => ['compara', 'compara_homology_annotation', 'compara_references', 'core', 'brc4_core', 'corelike', 'funcgen', 'schema', 'variation'],
  DB_TYPES    => ['cdna', 'compara', 'core', 'funcgen', 'otherfeatures', 'production', 'rnaseq', 'variation'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  my %file_schema;

  my $table_sql_file = $self->table_sql_file();
  my $table_sql = path($table_sql_file)->slurp;

  my @file_tables = $table_sql =~ /(CREATE TABLE[^;]+;)/gms;
  foreach (@file_tables) {
    my ($table_name, $table, $keys) = $self->normalise_table_def($_);
    $file_schema{$table_name} = {'table' => $table, 'keys' => $keys};
  }

  my %db_schema;

  my $helper = $self->dba->dbc->sql_helper();
  my $db_table_names = $helper->execute_simple(-SQL => 'show tables;');

  foreach my $table_name (@$db_table_names) {
    next if $table_name =~ /^MTMP/;
    my $sql = "show create table $table_name";
    my $db_table = $helper->execute_into_hash(-SQL => $sql);

    # Exclude views.
    if ($$db_table{$table_name} =~ /^CREATE TABLE/) {
      my (undef, $table, $keys) = $self->normalise_table_def($$db_table{$table_name});
      $db_schema{$table_name} = {'table' => $table, 'keys' => $keys};
    }
  }

  # If comparing the file and db hashes fails, run table-by-table.
  # The test stops on the first error, so if there are problems with
  # several tables this avoids an annoying fix/re-run/fix cycle.
  my $desc = "Database schema matches schema defined in file";
  my $pass = is_deeply(\%db_schema, \%file_schema, $desc);
  if (!$pass) {
    foreach my $table_name (sort keys %file_schema) {
      if (exists $db_schema{$table_name}) {
        my $desc_table = "Table definition matches for $table_name";
        is_deeply($db_schema{$table_name}, $file_schema{$table_name}, $desc_table);
      }
    }
  }
}

sub normalise_table_def {
  my ($self, $table) = @_;

  # Remove column/table name quoting.
  $table =~ s/`//gm;

  # Remove whitespace.
  $table =~ s/^\s+//gm;
  $table =~ s/[ \t]+/ /gm;
  $table =~ s/ +$//gm;
  $table =~ s/, +/,/gm;
  $table =~ s/ +,/,/gm;
  $table =~ s/\( /\(/gm;
  $table =~ s/ \)/\)/gm;
  $table =~ s/\n+/\n/gm;

  # Put ENUMs all on one line.
  $table =~ s/\n(['].*)/$1/gm;
  $table =~ s/\n\s*(\).*,)/$1/gm;

  # Closing parenthesis on its own line.
  $table =~ s/(\S*)(\);)/$1\n$2/gm;

  # Remove unnecessary test for existence.
  $table =~ s/ IF NOT EXISTS//gm;

  # Normalise case: everything after column name is upper-cased.
  $table =~ s/^([a-z]\w+\s)(.+)/$1\U$2/gm;

  # Use KEY rather than INDEX.
  $table =~ s/^INDEX /KEY /gm;

  # Remove KEY name (if not specified, it will be autogenerated,
  # which is hard to match robustly).
  $table =~ s/(KEY )\w+ */$1/gm;

  # Having a number in parentheses after an INT definition appears to be done
  # at random. It controls padding with zeroes, and can safely be ignored.
  $table =~ s/INT\(\d+\)/INT/gm;

  # The precision of FLOAT columns does not seem to be apparent from
  # the table definitions, so ignore it to prevent spurious differences.
  $table =~ s/FLOAT\(\d+\)/FLOAT/gm;

  # Having default NULL is, er, the default; sometimes it's explicit,
  # other times implicit, so remove it to be consistent.
  $table =~ s/\sDEFAULT NULL//gm;
  $table =~ s/\sUNSIGNED NULL/ UNSIGNED/gm;

  # Auto-increment fields are not null by default; sometimes it's explicit,
  # other times implicit, so remove it to be consistent.
  $table =~ s/NOT NULL AUTO_INCREMENT/AUTO_INCREMENT/gm; 

  # Quote all numeric defaults.
  $table =~ s/(\sDEFAULT )([\d\.]+)/$1'$2'/gm;

  # Ensure default is at the end, which is the standard place for it.
  $table =~ s/(\sDEFAULT '[^']*')([^,]+)/$2$1/gm;

  # Remove comments.
  $table =~ s/#.*//gm;
  $table =~ s/\-\-.*//gm;
  $table =~ s/\n+/\n/gm;

  # Remove things like collation and checksum status.
  $table =~ s/[^\)]+\Z//gm;
  $table =~ s/,\s*\)\Z/\n\)/m;

  # Key order can be variable, so extract into an ordered list.
  my @keys = $table =~ /^((?:PRIMARY |UNIQUE )*KEY.*),*/gm;
  foreach (@keys) {
    $_ =~ s/,$//;
  }

  # Foreign keys may or may not already exist as primary/unique keys.
  my @foreign_keys = $table =~ /^FOREIGN (KEY.*) REFERENCES.*,*/gm;
  foreach (@foreign_keys) {
    $_ =~ s/,$//;
  }

  foreach my $fk (@foreign_keys) {
    my $exists = 0;
    # Remove trailing parenthesis to match compound keys.
    (my $fk_tmp = $fk) =~ s/\)$//;
    foreach my $key (@keys) {
      if ($key =~ /\Q$fk_tmp\E/) {
        $exists = 1;
        last;
      }
    }
    if (! $exists) {
      push @keys, $fk;
    }
  }
  @keys = sort @keys;

  # Remove keys from table definition since they have been extracted.
  $table =~ s/^((?:PRIMARY |UNIQUE |FOREIGN )*KEY\s.*)\n//gm;

  my ($table_name) = $table =~ /CREATE TABLE (\S+)/m;

  return ($table_name, $table, \@keys);
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

1;
