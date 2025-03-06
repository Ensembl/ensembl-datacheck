=head1 LICENSE

Copyright [2018-2025] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::HomologyRanges;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'HomologyRanges',
  DESCRIPTION    => 'Gene-tree MLSSes have distinct homology ranges',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_master'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['method_link', 'method_link_species_set', 'method_link_species_set_tag']
};

sub skip_tests {
  my ($self) = @_;
  my $compara_dba = $self->dba;
  my $mlss_dba = $compara_dba->get_MethodLinkSpeciesSetAdaptor();

  my @gene_tree_mlsses;
  foreach my $method_type ('PROTEIN_TREES', 'NC_TREES') {
    my $mlsses_of_type = $mlss_dba->fetch_all_by_method_link_type($method_type);
    my @curr_mlsses_of_type = grep { $_->is_current } @{$mlsses_of_type};
    push(@gene_tree_mlsses, @curr_mlsses_of_type);
  }

  if (scalar(@gene_tree_mlsses) < 2) {
    my $msg = sprintf(
      "Homology range index check unnecessary as there are not multiple gene-tree MLSSes in %s",
      $compara_dba->dbc->dbname,
    );
    return(1, $msg);
  }
}


sub tests {
  my ($self) = @_;

  my $mlss_dba = $self->dba->get_MethodLinkSpeciesSetAdaptor();

  my @gene_tree_mlsses;
  foreach my $method_type ('PROTEIN_TREES', 'NC_TREES') {
    my $mlsses_of_type = $mlss_dba->fetch_all_by_method_link_type($method_type);
    my @curr_mlsses_of_type = grep { $_->is_current } @{$mlsses_of_type};
    push(@gene_tree_mlsses, @curr_mlsses_of_type);
  }

  my %mlsses_by_range_index;
  foreach my $gene_tree_mlss (sort { $a->dbID <=> $b->dbID } @gene_tree_mlsses) {
    my $range_index = $gene_tree_mlss->get_value_for_tag('homology_range_index');
    my $gene_tree_mlss_name = $gene_tree_mlss->name;

    my $desc_5 = "MLSS '$gene_tree_mlss_name' homology range index tag check";
    ok(defined($range_index), $desc_5);

    if (defined $range_index) {
      push(@{$mlsses_by_range_index{$range_index}}, $gene_tree_mlss_name);
    }
  }

  foreach my $range_index (sort { $a <=> $b } keys %mlsses_by_range_index) {
    my @gene_tree_mlss_names = sort @{$mlsses_by_range_index{$range_index}};
    my $desc_6 = "Homology range index '$range_index' uniqueness check";
    is(scalar(@gene_tree_mlss_names), 1, $desc_6)
      || diag explain [sort @gene_tree_mlss_names];
  }
}


1;
