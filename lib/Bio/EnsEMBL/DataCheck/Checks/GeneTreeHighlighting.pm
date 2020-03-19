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

package Bio::EnsEMBL::DataCheck::Checks::GeneTreeHighlighting;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'GeneTreeHighlighting',
  DESCRIPTION => 'GO and InterPro xrefs are loaded for highlighting annotated genes',
  GROUPS      => ['compara_annot_highlight'],
  DB_TYPES    => ['compara'],
  TABLES      => ['gene_member', 'member_xref']
};

sub skip_tests {
  my ($self) = @_;

  if ( $self->dba->get_division eq 'vertebrates' ) {
    return( 1, "Gene tree highlighting is not done for vertebrates" );
  } else {
    my $mlssa = $self->dba->get_adaptor("MethodLinkSpeciesSet");
    my $mlss = $mlssa->fetch_all_by_method_link_type('PROTEIN_TREES');

    if ( scalar(@$mlss) == 0 ) {
      return( 1, 'No gene trees in database' );
    }
  }
}

sub tests {
  my ($self) = @_;

  my @sources = ('GO', 'InterPro');
  foreach my $source (@sources) {
    my $desc = "Gene tree nodes annotated with $source";
    my $sql  = qq/
      SELECT COUNT(*) FROM
        external_db INNER JOIN
        member_xref USING (external_db_id) INNER JOIN
        gene_member USING (gene_member_id) 
      WHERE db_name = '$source'
    /;
    is_rows_nonzero($self->dba, $sql, $desc);
  }
  
  fk($self->dba, 'member_xref', 'gene_member_id', 'gene_member');
}

1;

