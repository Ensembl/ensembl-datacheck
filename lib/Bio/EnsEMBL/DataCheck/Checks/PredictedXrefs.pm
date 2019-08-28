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

package Bio::EnsEMBL::DataCheck::Checks::PredictedXrefs;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'PredictedXrefs',
  DESCRIPTION    => 'Check that RefSeqs xrefs are predictions',
  GROUPS         => ['compare_core', 'xref'],
  DB_TYPES       => ['core'],
  TABLES         => ['xref', 'external_db'],
  PER_DB         => 1
};

sub tests {
  my ($self) = @_;
  $self->predicted_xrefs_check("RefSeq_mRNA", "XM%","RefSeq mRNA accessions are not predictions");
  $self->predicted_xrefs_check("RefSeq_ncRNA", "XR%","RefSeq ncRNA accessions are not predictions");
  $self->predicted_xrefs_check("RefSeq_peptide", "XP%","RefSeq peptide accessions are not predictions");
}

sub predicted_xrefs_check{
  my ($self,$refseq_name,$pattern,$desc) = @_;    
  my $sql  = qq/
      SELECT COUNT(*) FROM xref x, external_db e
      WHERE
        x.external_db_id = e.external_db_id AND
        e.db_name = '$refseq_name' AND
        x.dbprimary_acc LIKE '$pattern'
    /;
    is_rows_zero($self->dba, $sql, $desc);
}

1;