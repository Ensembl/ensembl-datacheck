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

package Bio::EnsEMBL::DataCheck::Checks::MetaKeyAlias;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
    NAME           => 'MetaKeyAlias',
    DESCRIPTION    => 'Comparison of aliases between releases',
    GROUPS         => [ 'core_handover' ],
    DB_TYPES       => [ 'core' ],
    TABLES         => [ 'meta' ],
    DATACHECK_TYPE => 'advisory'

};

sub tests {
    my $old_dba = $self->get_old_dba();
    SKIP: {

        skip 'No old version of database', 1 unless defined $old_dba;

        my $mca = $self->dba->get_adaptor('MetaContainer');
        my $old_mca = $old_dba->get_adaptor('MetaContainer');

        my @new_alias = $mca->list_value_by_key('species.alias');
        my @old_alias = $old_mca->list_value_by_key('species.alias');

        my %count;
        for my $element (@new_alias, @old_alias) {
            $count{$element}++;
        }
        for my $element (values %count) {
            ok($element == 2, 'species.alias is found in both databases')
        }
    }
}

1;