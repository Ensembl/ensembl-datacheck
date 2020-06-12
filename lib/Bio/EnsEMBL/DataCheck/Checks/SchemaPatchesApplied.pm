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

package Bio::EnsEMBL::DataCheck::Checks::SchemaPatchesApplied;

use warnings;
use strict;

use Moose;
use Path::Tiny;
use Test::More;
use Bio::EnsEMBL::DataCheck::Utils qw/repo_location/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SchemaPatchesApplied',
  DESCRIPTION => 'Schema patches are up-to-date',
  GROUPS      => ['brc4_core', 'compara', 'compara_gene_trees', 'compara_genome_alignments', 'compara_master', 'compara_syntenies', 'core', 'corelike', 'funcgen', 'schema', 'variation'],
  DB_TYPES    => ['cdna', 'compara', 'core', 'funcgen', 'otherfeatures', 'production', 'rnaseq', 'variation'],
  TABLES      => ['meta'],
  PER_DB      => 1,
};

sub tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");

  my $db_patches = $mca->list_value_by_key('patch');

  my %db_patches;
  foreach my $db_patch (@$db_patches) {
    $db_patch =~ s/\|.*$//;
    $db_patch =~ /patch_(\d+)_\d+_(\w+)/;
    $db_patches{$1}{$2} = $db_patch;
  }

  my @db_patches;
  foreach my $number (sort {$a <=> $b} keys %db_patches) {
    foreach my $letter (sort keys %{$db_patches{$number}}) {
      push @db_patches, $db_patches{$number}{$letter};
    }
  }

  my $file_patches = $self->file_patches();

  my $oldest_in_db = $db_patches[0];
  my $index;
  foreach my $file_patch (@$file_patches) {
    if ($oldest_in_db eq $file_patch) {
      last;
    } else {
      $index++;
    }
  }
  my @relevant_file_patches = splice(@$file_patches, $index);

  my $desc = "All schema patches have been applied";
  my $pass = is_deeply(\@db_patches, \@relevant_file_patches, $desc);

  if (!$pass) {
    my %db_patches = map { $_ => 1 } @db_patches;
    foreach (@relevant_file_patches) {
      diag("$_ missing from database") unless exists $db_patches{$_};
    }
  }
}

sub file_patches {
  my ($self) = @_;

  # Don't need checking here, the DB_TYPES ensure we won't get
  # a $dba from a group that we can't handle, and the repo_location
  # method will die if the repo path isn't visible to Perl.
  my $repo_location  = repo_location($self->dba->group);
  my $sql_dir = "$repo_location/sql";

  my %file_patches;
  if (-e $sql_dir) {
    my @files = path($sql_dir)->children(qr/^patch_\d+_\d+_\w+\.sql$/);
    foreach my $file ( @files ) {
      $file->basename =~ /patch_(\d+)_\d+_(\w+)/;
      $file_patches{$1}{$2} = $file->basename;
    }
  } else {
    die "SQL directory does not exist: $sql_dir";
  }

  my @file_patches;
  foreach my $number (sort {$a <=> $b} keys %file_patches) {
    foreach my $letter (sort keys %{$file_patches{$number}}) {
      push @file_patches, $file_patches{$number}{$letter};
    }
  }

  return \@file_patches;
}

1;
