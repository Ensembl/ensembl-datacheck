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

package Bio::EnsEMBL::DataCheck::Checks::AltAllele;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
    NAME        => 'AltAllele',
    DESCRIPTION => 'Ensure Alternative Allele group members all map back to the same base seq region',
    GROUPS      => ['core_handover'],
    DB_TYPES    => [ 'core' ],
};



sub tests {
    my ($self) = @_;

    my $sql_allele_check = qq/
        SELECT *
        FROM (
            SELECT  aa.alt_allele_group_id,
                    GROUP_CONCAT(
                        DISTINCT
                            IFNULL( ae.exc_seq_region_id, g.seq_region_id)
                            ORDER BY ae.exc_seq_region_id IS NULL DESC
                            SEPARATOR ';')
                    AS seq_regions_check,
                    GROUP_CONCAT(
                        DISTINCT CONCAT(
                            IFNULL( ae.exc_seq_region_id, -1),',', g.seq_region_id, ',',
                                    IFNULL(ae.exc_type, 'NULL'))
                            ORDER BY ae.exc_seq_region_id IS NULL DESC
                            SEPARATOR ';')
                            as seq_regions
            FROM alt_allele_group aag
            LEFT JOIN alt_allele aa USING (alt_allele_group_id)
            LEFT JOIN gene g USING (gene_id)
            LEFT JOIN seq_region sr USING (seq_region_id)
            LEFT JOIN assembly_exception ae USING (seq_region_id)
            GROUP BY alt_allele_group_id
            ) as req
        WHERE length(seq_regions_check) - length(replace(seq_regions_check, ';', '')) + 1 > 1;
    /;

    my $diag_allele_check = 'Row with non-matching seq_regions for AltAllele group';
    my $desc_allele_check = 'Alternative Allele mapping';

    my $helper = $self->dba->dbc->sql_helper;

    $helper->execute(q/
        SET SESSION group_concat_max_len = 2048;
    /);
    is_rows_zero($self->dba, $sql_allele_check, $desc_allele_check, $diag_allele_check);

    # Check that no 'PAR' exc_type is present in the alt_alleles
    my $sql_allele_check_par_type = q/
        SELECT  aa.alt_allele_group_id
        FROM alt_allele_group aag
        LEFT JOIN alt_allele aa USING (alt_allele_group_id)
        LEFT JOIN gene g USING (gene_id)
        LEFT JOIN seq_region sr USING (seq_region_id)
        LEFT JOIN assembly_exception ae USING (seq_region_id)
        WHERE ae.exc_type = 'PAR'
        GROUP BY alt_allele_group_id
    /;

    my $diag_check_par_type = 'AltAllele group exception with "PAR" type';
    my $desc_check_par_type = '"PAR" assembly exception type in AltAllele';

    is_rows_zero($self->dba, $sql_allele_check_par_type, $desc_check_par_type, $diag_check_par_type);
}

1;