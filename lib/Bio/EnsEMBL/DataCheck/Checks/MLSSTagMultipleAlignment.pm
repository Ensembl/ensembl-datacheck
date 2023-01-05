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

package Bio::EnsEMBL::DataCheck::Checks::MLSSTagMultipleAlignment;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::Compara;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MLSSTagMultipleAlignment',
  DESCRIPTION => 'Multiple alignments have appropriate tags',
  GROUPS      => ['compara', 'compara_genome_alignments'],
  DB_TYPES    => ['compara'],
  TABLES      => ['method_link', 'method_link_species_set', 'method_link_species_set_tag']
};

sub skip_tests {
  my ($self) = @_;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my @methods = qw( EPO EPO_EXTENDED PECAN );
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

  my $tags = [
    'num_blocks',
    'max_align',
  ];

  has_tags($self->dba, 'EPO', $tags);
  has_tags($self->dba, 'PECAN', $tags);

  push @$tags, 'base_mlss_id';
  has_tags($self->dba, 'EPO_EXTENDED', $tags);

  my $desc = "Extended multiple sequence alignments tagged with base MSA MLSS ID";
  my $sql = qq/
    SELECT
      mlss1.method_link_species_set_id,
      mlss2.method_link_species_set_id
    FROM
      method_link_species_set mlss1 INNER JOIN
      method_link ml1 ON mlss1.method_link_id = ml1.method_link_id INNER JOIN
      method_link_species_set_tag mlsst ON
        mlss1.method_link_species_set_id = mlsst.method_link_species_set_id
        LEFT OUTER JOIN
        (
          SELECT method_link_species_set_id FROM
            method_link_species_set INNER JOIN
            method_link USING (method_link_id)
          WHERE
            type = "EPO"
        ) mlss2 ON mlsst.value = mlss2.method_link_species_set_id
    WHERE
      ml1.type = "EPO_EXTENDED" AND
      mlsst.tag = "base_mlss_id" AND
      mlss2.method_link_species_set_id IS NULL
  /;
  is_rows_zero($self->dba, $sql, $desc);
}

1;
