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

package Bio::EnsEMBL::DataCheck::Checks::MLSSTagGERP;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::Compara;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MLSSTagGERP',
  DESCRIPTION => 'GERP analyses have appropriate tags',
  GROUPS      => ['compara', 'compara_genome_alignments'],
  DB_TYPES    => ['compara'],
  TABLES      => ['method_link', 'method_link_species_set', 'method_link_species_set_tag']
};

sub skip_tests {
  my ($self) = @_;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my @methods = qw( EPO EPO_LOW_COVERAGE );
  my $db_name = $self->dba->dbc->dbname;
  
  my @mlsses;
  foreach my $method ( @methods ) {
    my $mlss = $mlss_adap->fetch_all_by_method_link_type($method);
    push @mlsses, @$mlss;
  }
  
  if ( scalar(@mlsses) == 0 ) {
    return( 1, "There are no multiple alignments in $db_name" );
  }
}

sub tests {
  my ($self) = @_;

  has_tags($self->dba, 'GERP_CONSTRAINED_ELEMENT', ['max_align', 'msa_mlss_id']);
  has_tags($self->dba, 'GERP_CONSERVATION_SCORE',  ['msa_mlss_id']);

  my $desc = "GERP analysis tagged with appropriate MSA MLSS ID";
  my $sql  = qq/
    SELECT
      mlss1.method_link_species_set_id,
      mlss2.method_link_species_set_id,
      ml1.type,
      ml2.type,
      mlsst.value
    FROM
      method_link_species_set mlss1 INNER JOIN
      method_link_species_set mlss2 ON (mlss1.species_set_id = mlss2.species_set_id) INNER JOIN
      method_link ml1 ON mlss1.method_link_id = ml1.method_link_id INNER JOIN
      method_link ml2 ON mlss2.method_link_id = ml2.method_link_id INNER JOIN
      method_link_species_set_tag mlsst ON mlss1.method_link_species_set_id = mlsst.method_link_species_set_id
    WHERE
      (ml1.class = "ConservationScore.conservation_score" OR
       ml1.class = "ConstrainedElement.constrained_element") AND
      (ml2.class = "GenomicAlignBlock.multiple_alignment" OR
       ml2.class LIKE "GenomicAlignTree.%") AND
      ml1.type NOT LIKE "pGERP%" AND
      ml2.type NOT LIKE "pEPO%" AND
      mlsst.tag = "msa_mlss_id" AND
      mlss2.method_link_species_set_id <> mlsst.value
  /;
  is_rows_zero($self->dba, $sql, $desc);
}

1;
