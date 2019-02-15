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

package Bio::EnsEMBL::DataCheck::Checks::StableIDUnique;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'StableIDUnique',
  DESCRIPTION => 'Stable IDs are unique, both within a database, and across all databases in the registry',
  GROUPS      => ['core', 'corelike', 'geneset'],
  DB_TYPES    => ['core', 'otherfeatures'],
  TABLES      => ['gene', 'transcript', 'translation'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  foreach my $table (@{$self->tables}) {
    my $desc = "Unique stable IDs in $table table";
    my $diag = "Stable ID";
    my $sql  = qq/
      SELECT stable_id FROM $table
      GROUP BY stable_id HAVING COUNT(*) > 1
    /;
    is_rows_zero($self->dba, $sql, $desc, $diag);
  }

  my $group = $self->dba->group;

  foreach my $table (@{$self->tables}) {
    my $sql    = "SELECT stable_id FROM $table";
    my $helper = $self->dba->dbc->sql_helper;
    my $ids    = $helper->execute_simple(-SQL => $sql);
    $self->dba->dbc && $self->dba->dbc->disconnect_if_idle();

    my %all_ids;
    my %dbs;
    my $all_dbas = $self->registry->get_all_DBAdaptors(-GROUP => $group);
    foreach my $dba (@$all_dbas) {
      my $dbname = $dba->dbc->dbname;
      next if exists $dbs{$dbname};
      $dbs{$dbname}++;

      $helper = $dba->dbc->sql_helper;
      my $all_ids = $helper->execute_simple(-SQL => $sql);
      $dba->dbc && $dba->dbc->disconnect_if_idle();

      map { push @{ $all_ids{$_} }, $dbname } @$all_ids;
    }

    my @duplicated;
    foreach my $id (sort @$ids) {
      if (scalar @{ $all_ids{$id} } > 1) {
        push @duplicated, ("$id in multiple databases: " . join(", ", @{ $all_ids{$id} }));
      }
    }
    my $desc = "Unique stable IDs across all $table tables";
    is(scalar @duplicated, 0, $desc) or diag(\@duplicated);
  }
}

1;
