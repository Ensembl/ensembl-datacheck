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

package Bio::EnsEMBL::DataCheck::Checks::GenomeDBCore;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'GenomeDBCore',
  DESCRIPTION => 'Species, assembly, and geneset metadata are the same in core and compara databases',
  GROUPS      => ['compara', 'compara_master'],
  DB_TYPES    => ['compara']
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

    my $mca = $core_dba->get_adaptor('MetaContainer');

    my $species   = $mca->single_value_by_key('species.production_name');
    my $taxon_id  = $mca->single_value_by_key('species.taxonomy_id');
    my $assembly  = $mca->single_value_by_key('assembly.default');
    my $genebuild = $mca->single_value_by_key('genebuild.start_date');

    my $desc_2 = "Species name matches for $gdb_name";
    is($genome_db->name, $species, $desc_1);

    my $desc_3 = "Taxonomy ID matches for $gdb_name";
    is($genome_db->taxon_id, $taxon_id, $desc_2);

    my $desc_4 = "Assembly matches for $gdb_name";
    is($genome_db->assembly, $assembly, $desc_3);

    my $desc_5 = "Genebuild matches for $gdb_name";
    is($genome_db->genebuild, $genebuild, $desc_4);
  }
}

1;
