=head1 LICENSE

Copyright [2018] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::ExonStrandOrder;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
    NAME        => 'ExonStrandOrder',
    DESCRIPTION => 'Checks all exon of a gene are on the same strand and in the correct order in their transcript.',
    DB_TYPES    => [ 'core' ],
    GROUPS      => [ 'core_handover' ],
};

sub tests {
  my ($self) = @_;

  my $mapper = sub {
    my ($row, $value) = @_;
    my %row = (
        gene_id           => $$row[0],
        transcript_id     => $$row[1],
        transcript_strand => $$row[2],
        exon_id           => $$row[3],
        exon_start        => $$row[4],
        exon_end          => $$row[5],
        exon_strand       => $$row[6],
        exon_rank         => $$row[7],
        gene_stable_id    => $$row[8],
        trans_stable_id   => $$row[9]
    );
    return \%row;
  };

  my $sql_strand_order = q/
    SELECT  g.gene_id,
            tr.transcript_id,
            tr.seq_region_strand,
            e.exon_id,
            e.seq_region_start,
            e.seq_region_end,
            e.seq_region_strand,
            et.`rank`,
            g.stable_id,
            tr.stable_id
    FROM    gene g
    INNER JOIN transcript tr USING (gene_id)
    INNER JOIN exon_transcript et  USING (transcript_id)
    INNER JOIN exon e USING (exon_id)
    WHERE  tr.transcript_id NOT IN (
	          SELECT  transcript_id
	          FROM    transcript_attrib
	          INNER JOIN attrib_type
	          USING (attrib_type_id)
	          WHERE code='trans_spliced')
    ORDER BY et.transcript_id, et.`rank`
    LIMIT 10
    /;
  my $lastTranscriptID = -1;
  my $lastExonStart = -1;
  my $lastExonEnd = -1;
  my $lastExonStrand = -2;
  my $lastExonID = -1;
  my $lastExonRank = 0;

  my @genes_exons_strand = @{$self->dba->dbc->sql_helper->execute_simple(-SQL => $sql_strand_order, -CALLBACK => $mapper)};
  foreach my $strand (@genes_exons_strand) {
    print $$strand{gene_id} . "  --- \n";
    if ($$strand{transcript_id} == $lastTranscriptID) {
      if ($lastExonStrand < -1) {
        $lastExonStrand = $$strand{seq_region_strand};
        $lastExonStart = $$strand{exon_strand};
        $lastExonEnd = $$strand{exon_end};
        $lastExonID = $$strand{exon_id};
        $lastExonRank = $$strand{exon_rank};
      }
      else {

      }
    }
  }

}

1;
