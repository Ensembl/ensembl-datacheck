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

package Bio::EnsEMBL::DataCheck::Checks::AltAlleleGroup;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
    NAME        => 'AltAlleleGroup',
    DESCRIPTION => 'Ensure that there are no alt_allele_group members that contains more than 1 gene on the primary assesmbly',
    GROUPS      => [ 'core_handover' ],
    DB_TYPES    => [ 'core' ]
};

sub tests {
    my ($self) = @_;

    my $sql_allele_group_check = qq/
        SELECT  COUNT(alt_allele_group_id) AS cnt,
                alt_allele_group_id
        FROM (
            SELECT  aa.*,
                    ae.exc_type
            FROM alt_allele aa
            LEFT JOIN gene g USING (gene_id)
            LEFT JOIN assembly_exception ae USING (seq_region_id)
            WHERE exc_type IS NULL
        ) AS aaexc
        GROUP BY    alt_allele_group_id
        HAVING cnt > 1
    /;

    my $diag_allele_group_check = 'Row with non-matching seq_regions for AltAllele group';
    my $desc_allele_group_check = 'Alternative Allele mapping';

    is_rows_zero($self->dba, $sql_allele_group_check, $desc_allele_group_check, $diag_allele_group_check);
}

1;