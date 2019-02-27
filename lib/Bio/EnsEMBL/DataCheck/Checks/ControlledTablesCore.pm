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

package Bio::EnsEMBL::DataCheck::Checks::ControlledTablesCore;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ControlledTablesCore',
  DESCRIPTION => 'Controlled tables are consistent with production database',
  GROUPS      => ['controlled_tables', 'core', 'corelike'],
  DB_TYPES    => ['cdna', 'core', 'otherfeatures', 'rnaseq'],
  TABLES      => ['attrib_type', 'biotype', 'external_db', 'misc_set', 'unmapped_reason'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;
  my $helper = $self->dba->dbc->sql_helper;
  my $prod_dba = $self->get_dba('multi', 'production');
  my $prod_helper = $prod_dba->dbc->sql_helper;

  foreach my $table ( @{$self->tables} ) {
    # We need things returned in a consistent order, for which we need
    # columns names. Easiest way to get them is to return one row.
    my $row_sql  = "SELECT * FROM $table LIMIT 1";
    my @row = @{ $helper->execute(-SQL => $row_sql, -use_hashrefs => 1) };
    my $columns = join(", ", keys %{$row[0]});

    my $sql = "SELECT * FROM $table ORDER BY $columns";
    my @data = @{ $helper->execute(-SQL => $sql, -use_hashrefs => 1) };

    my $prod_table = "master_$table";
    my $prod_sql   = "SELECT $columns FROM $prod_table WHERE is_current = 1 ORDER BY $columns";
    my @prod_data  = @{ $prod_helper->execute(-SQL => $prod_sql, -use_hashrefs => 1) };

    # Deal with column which is _not_ necessarily the same...
    if ($table eq 'external_db') {
      map { delete($_->{'db_release'}) } @data;
      map { delete($_->{'db_release'}) } @prod_data;
    }

    # Create hashes of db rows, indexed on the tables auto-increment ID.
    my %data;
    my %prod_data;
    
    my $id_column = "$table\_id";

    foreach (@data) {
      my $id = $_->{$id_column};
      push @{ $data{$id} }, $_;
    }
    foreach (@prod_data) {
      my $id = $_->{$id_column};
      push @{ $prod_data{$id} }, $_;
    }

    # We do not compare the core and prod hashes in a single test, because
    # we allow entries in the prod db that are not in the core db. We could
    # use a Test::Deep method instead, but that module does not provide
    # adequate diagnostic messages.
    foreach my $id (sort {$a <=> $b} keys %data) {
      if (exists $prod_data{$id}) {
        my $desc = "Data in $table ($id_column: $id) is consistent";
        is_deeply($data{$id}, $prod_data{$id}, $desc);
      } else {
        my $desc = "Data in $table ($id_column: $id) exists in master table";
        fail($desc);
      }
    }
  }
}

1;
