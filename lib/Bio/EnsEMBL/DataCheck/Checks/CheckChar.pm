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

package Bio::EnsEMBL::DataCheck::Checks::CheckChar;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
    NAME        => 'CheckChar',
    DESCRIPTION => 'Check that imported names/descriptions contains only supported characters',
};

sub tests {
    my ($self) = @_;

    # Test description length
    my $sql_length = qq/
        SELECT name
        FROM phenotype
        WHERE description IS NOT NULL
        AND LENGTH(description) < 4
    /;
    my $desc_length = 'Phenotype description length';
    my $diag_length = "Phenotype is suspiciously short";
    is_rows_zero($self->dba, $sql_length, $desc_length, $diag_length);

    # Test description new line character
    my $sql_newline = qq/
        SELECT name
        FROM phenotype
        WHERE description IS NOT NULL
        AND description LIKE '%\n%'
    /;
    my $desc_newline = 'Phenotype description with new line';
    my $diag_newline = "Phenotype is suspiciously short";
    is_rows_zero($self->dba, $sql_newline, $desc_newline, $diag_newline);

    # Test ASCII vars
    my $sql_ascii = qq/
        SELECT name, description
        FROM phenotype
        WHERE description NOT REGEXP '[ -~]'
        OR description REGEXP '.*\<.*\>.*'
    /;
    my $desc_ascii = 'Phenotype description with unsupported character';
    my $diag_ascii = "Phenotype has suspect start or unsupported characters";
    is_rows_zero($self->dba, $sql_ascii, $desc_ascii, $diag_ascii);

    # Check non terms in description
    my $sql_non_term = qq/
        SELECT name, description
        FROM phenotype
        WHERE lower(description) in ("none", "not provided", "not specified", "not in omim", "variant of unknown significance", "not_provided", "?", ".")
    /;
    my $desc_non_term = 'Phenotype description suggests no phenotype';
    my $diag_non_term = 'Phenotype is not useful';
    is_rows_zero($self->dba, $sql_non_term, $desc_non_term, $diag_non_term);

}

1;

