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

package Bio::EnsEMBL::DataCheck::Checks::ExonRank;

use warnings;
use strict;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
    NAME        => 'ExonRank',
    DESCRIPTION => 'Check for entries in the exon_transcript table that are duplicates apart from the rank',
    GROUPS      => [ 'core_handover' ],
    DB_TYPES    => [ 'core' ]
};

sub tests {
    my ($self) = @_;

    my $descexon_rank = 'Exon/Transcript rank count';
    my $diagexon_rank = "Same Exon/Transcript with different ranks";
    my $sqlexon_rank = qq/
        SELECT  exon_id,
                transcript_id,
                GROUP_CONCAT(`rank` SEPARATOR '-')
        FROM exon_transcript
        GROUP BY exon_id, transcript_id
        HAVING COUNT(`rank`) > 1
    /;
    is_rows_zero($self->dba, $sqlexon_rank, $descexon_rank, $diagexon_rank);

}

1;

