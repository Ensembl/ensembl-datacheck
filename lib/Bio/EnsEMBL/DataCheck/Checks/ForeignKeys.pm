=head1 LICENSE

Copyright [2018] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::ForeignKeys;

use warnings;
use strict;
use feature 'say';

use Moose;
use Path::Tiny;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/repo_location/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ForeignKeys',
  DESCRIPTION => 'Check for incorrect foreign key relationships, as defined by a "foreign_keys.sql" file.',
  DB_TYPES    => ['compara', 'core', 'funcgen', 'otherfeatures', 'variation'],
  PER_DB      => 1,
};

sub tests {
  my ($self) = @_;
  
  my $fk_sql_file = $self->fk_sql_file();

  foreach my $line ( path($fk_sql_file)->lines ) {
    next unless $line =~ /FOREIGN KEY/;

    my ($table1, $col1, $table2, $col2) = $line =~
      /ALTER\s+TABLE\s+(\S+)\s+ADD\s+FOREIGN\s+KEY\s+\((\S+)\)\s+REFERENCES\s+(\S+)\s*\((\S+)\)/i;

    if (defined $table1 && defined $col1 && defined $table2 && defined $col2) {
      # In theory, need exceptions for gene_archive.peptide_archive_id and object_xref.analysis_id
      # which can be zero. But really, they should be null. And if they're not supposed
      # to be null, then they shouldn't be zero either.
       fk($self->dba, $table1, $col1, $table2, $col2);
    } else {
      die "Failed to parse foreign key relationship from $line";
    }
  }
}

sub fk_sql_file {
  my ($self) = @_;

  my %repo_names = (
    'compara'       => 'ensembl-compara',
    'core'          => 'ensembl',
    'funcgen'       => 'ensembl-funcgen',
    'otherfeatures' => 'ensembl',
    'variation'     => 'ensembl-variation',
  );

  # Don't need checking here, the DB_TYPES ensure we won't get
  # a $dba from a group that we can't handle, and the repo_location
  # method will die if the repo path isn't visible to Perl.
  my $repo_name     = $repo_names{$self->dba->group};
  my $repo_location = repo_location($repo_name);
  my $fk_sql_file   = "$repo_location/sql/foreign_keys.sql";

  if (! -e $fk_sql_file) {
    die "Foreign keys file does not exist: $fk_sql_file";
  }

  return $fk_sql_file;
}

1;
