=head1 LICENSE

Copyright [2018-2023] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::GenomeDBCore;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'GenomeDBCore',
  DESCRIPTION => 'Species, assembly, and geneset metadata are the same in core and compara databases',
  GROUPS      => ['compara', 'compara_gene_trees', 'compara_genome_alignments', 'compara_master', 'compara_syntenies', 'core_sync'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES    => ['compara'],
  TABLES      => ['genome_db'],
};

sub tests {
  my ($self) = @_;

  my $gdba = $self->dba->get_GenomeDBAdaptor;

  my $genome_dbs = $gdba->fetch_all_current();
  foreach my $genome_db (sort { $a->name cmp $b->name } @$genome_dbs) {
    my $gdb_name = $genome_db->name;
    
    next if $gdb_name eq 'ancestral_sequences';

    my $core_dba = $self->get_dba($genome_db->name, 'core');

    my $desc_1 = "Core database found for $gdb_name";
    next unless ok(defined $core_dba, $desc_1);

    # Let the API build a fresh object as per the information in the Core database
    my $expected_genome_db = Bio::EnsEMBL::Compara::GenomeDB->new_from_DBAdaptor($core_dba, $genome_db->genome_component);

    # Compare it to the object we have in the Compara database
    my $diffs = $genome_db->_check_equals($expected_genome_db);

    # Complain if there are any differences
    my $desc = "The GenomeDB matches the Core database";
    ok(!$diffs, $desc);
    diag($diffs) if $diffs;

    $core_dba->dbc->disconnect_if_idle;
  }
}

1;
