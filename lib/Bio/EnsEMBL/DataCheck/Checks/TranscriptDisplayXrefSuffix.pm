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

package Bio::EnsEMBL::DataCheck::Checks::TranscriptDisplayXrefSuffix;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'TranscriptDisplayXrefSuffix',
  DESCRIPTION    => 'Transcripts do not have a display xref with a -20* suffix. These are created by the non-vert Xref pipeline unless a flag is enabled: http://www.ebi.ac.uk/seqdb/confluence/display/EnsGen/Xref+mapping#Xrefmapping-CustomisingXrefMapping(DisplayXrefs)',
  GROUPS         => ['xref', 'xref_gene_symbol_transformer', 'core'],
  DB_TYPES       => ['core'],
  TABLES         => ['transcript', 'xref', 'object_xref','seq_region','coord_system'],
};


sub skip_tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor('MetaContainer');
  my $division = $mca->get_division;
  if ($division eq 'EnsemblVertebrates') {
    return (1, 'Vertebrate Transcript display xrefs are allowed to have a -20* suffix');
  }
}

sub tests {
  my ($self) = @_;

  my $desc = 'Transcripts do not have display_xrefs with a -20* suffix';
  my $diag = 'Transcript stable IDs';
  my $sql  = qq/
    SELECT distinct t.stable_id FROM
      transcript t INNER JOIN 
      xref x on t.display_xref_id = x.xref_id INNER JOIN
      object_xref USING (xref_id) INNER JOIN
      seq_region USING (seq_region_id) INNER JOIN
      coord_system USING (coord_system_id)
    WHERE x.dbprimary_acc regexp '-20[[:digit:]]\$' AND
      x.dbprimary_acc = x.display_label AND
      ensembl_object_type = 'Transcript' AND
      species_id = %d
  /;
  my $sql1 = sprintf($sql, $self->dba->species_id);

  is_rows_zero($self->dba, $sql1, $desc, $diag);
}

1;
