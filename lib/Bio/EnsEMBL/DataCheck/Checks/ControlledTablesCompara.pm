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

package Bio::EnsEMBL::DataCheck::Checks::ControlledTablesCompara;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/ hash_diff /;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'ControlledTablesCompara',
  DESCRIPTION    => 'Controlled tables are consistent with compara master database',
  GROUPS         => ['controlled_tables', 'compara', 'compara_master'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['compara'],
  TABLES         => ['genome_db', 'mapping_session', 'method_link', 'method_link_species_set', 'ncbi_taxa_node', 'species_set_header']
};

sub tests {
  my ($self) = @_;

  my $helper = $self->dba->dbc->sql_helper;

  if ($self->dba->dbc->dbname !~ /master/) {
    my $master_tables = [
      'genome_db',
      'mapping_session',
      'method_link',
      'method_link_species_set',
      'species_set_header',
    ];
    $self->master_tables($helper, $master_tables);
  }

  # The ncbi_taxa_name table has rows added in the compara db;
  # so don't check that, ncbi_taxa_node is sufficient to check
  # whether we're up to date.
  my $taxonomy_tables = ['ncbi_taxa_node'];
  $self->taxonomy_tables($helper, $taxonomy_tables);
}

sub master_tables {
  my ($self, $helper, $tables) = @_;

  # This test requires a compara_master database in the registry,
  # where the 'species' parameter is the same as the database name.
  my $desc_1 = "Compara master database found";
  my $master_db_name = 'ensembl_compara_master';
  my $division = $self->dba->get_division;
  if ($division ne 'vertebrates') {
    $master_db_name =~ s/ensembl/$division/;
  }
  my $master_dba = $self->get_dba($master_db_name, 'compara');

  if (ok(defined $master_dba, $desc_1)) {
    my $master_helper = $master_dba->dbc->sql_helper;

    foreach my $table (@$tables) {
      my $count_sql = "SELECT COUNT(*) FROM $table";
      my $desc_2 = "Table '$table' is populated";
      my $populated = is_rows_nonzero($self->dba, $count_sql, $desc_2);

      if ($populated) {
        my $id_column = $table eq 'species_set_header' ? 'species_set_id' : "${table}_id";
        $self->consistent_data($helper, $master_helper, $table, $id_column)
      }
    }
  }
}

sub consistent_data {
  my ($self, $helper, $master_helper, $table, $id_column) = @_;

  my $sql = "SELECT * FROM $table $sql_filter";
  my @data =
    @{ $helper->execute(-SQL => $sql, -use_hashrefs => 1) };
  my @master_data =
    @{ $master_helper->execute(-SQL => $sql, -use_hashrefs => 1) };

  # Create hashes of db rows, indexed on the tables auto-increment ID.
  my %data;
  my %master_data;

  foreach (@data) {
    my $id = $_->{$id_column};
    $data{$id} = $_;
  }
  foreach (@master_data) {
    my $id = $_->{$id_column};
    $master_data{$id} = $_;
  }

  # We do not compare the compara and master hashes in a single test, because
  # we allow entries in the master db that are not in the compara db. We could
  # use a Test::Deep method instead, but that module does not provide
  # adequate diagnostic messages.
  my @not_in_master;
  my @not_consistent;
  foreach my $id (sort {$a <=> $b} keys %data) {
    if (exists $master_data{$id}) {
      # Do this rather than 'is_deeply' to avoid an
      # excessive number of 'ok' messages.
      my $diff = hash_diff($data{$id}, $master_data{$id});
      if (
        keys(%{$diff->{'Different values'}}) ||
        keys(%{$diff->{'In first set only'}}) ||
        keys(%{$diff->{'In second set only'}})
      ) {
        push @not_consistent, "$table ($id_column: $id)";
      }
    } else {
      push @not_in_master, "$table ($id_column: $id)";
    }
  }

  my $desc_3 = "All '$table' data exists in master table";
  is(scalar(@not_in_master), 0, $desc_3) ||
    diag explain \@not_in_master;

  my $desc_4 = "All '$table' data is consistent";
  is(scalar(@not_consistent), 0, $desc_4) ||
    diag explain \@not_consistent;
}

sub taxonomy_tables {
  my ($self, $helper, $tables) = @_;
  
  my $desc_1 = "Taxonomy database found";
  my $taxonomy_dba = $self->get_dba('multi', 'taxonomy');

  if (ok(defined $taxonomy_dba, $desc_1)) {
    my $taxonomy_helper = $taxonomy_dba->dbc->sql_helper;

    foreach my $table (@$tables) {
      my $desc = "$table is identical in compara and taxonomy database";

      my $sql = "CHECKSUM TABLE $table";

      my $compara = $helper->execute( -SQL => $sql );
      my $taxonomy = $taxonomy_helper->execute( -SQL => $sql );
      is($$compara[0][1], $$taxonomy[0][1], $desc);
    }
  }
}

1;
