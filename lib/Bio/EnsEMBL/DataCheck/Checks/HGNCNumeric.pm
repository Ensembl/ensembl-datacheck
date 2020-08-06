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

package Bio::EnsEMBL::DataCheck::Checks::HGNCNumeric;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;;
extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'HGNCNumeric',
  DESCRIPTION    => 'HGNC xrefs do not have the accession as the display_label',
  GROUPS         => ['core', 'xref', 'xref_mapping'],
  TABLES         => ['coord_system', 'external_db', 'gene', 'object_xref', 'seq_region', 'xref'],
};

sub tests {
  my ($self) = @_;

  my $species_id = $self->dba->species_id;

  my $desc_1 = "HGNC xrefs do not have the accession as the display_label";
  my $sql_1  = qq/
    SELECT COUNT(*) FROM
      object_xref ox INNER JOIN
      xref x USING (xref_id) INNER JOIN
      external_db e USING (external_db_id) INNER JOIN
      gene g ON ox.ensembl_id = g.gene_id INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id) 
    WHERE
      cs.species_id = $species_id AND
      e.db_name LIKE 'HGNC%' AND
      ox.ensembl_object_type = 'Gene' AND
      x.dbprimary_acc = x.display_label
  /;
  is_rows_zero($self->dba, $sql_1, $desc_1);
}

1;
