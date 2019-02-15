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

package Bio::EnsEMBL::DataCheck::Checks::Denormalized;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'Denormalized',
  DESCRIPTION => 'Denormalized columns are synchronised',
  GROUPS      => ['variation', 'schema'],
  DB_TYPES    => ['variation']
};

sub tests {
  my ($self) = @_;

  if ($self->dba->group eq 'variation') {
    denormalized($self->dba, 'variation',            'variation_id',            'somatic', 'variation_feature');
    denormalized($self->dba, 'variation_feature',    'variation_feature_id',    'somatic', 'transcript_variation');
    denormalized($self->dba, 'structural_variation', 'structural_variation_id', 'somatic', 'structural_variation_feature');
    denormalized($self->dba, 'variation',            'variation_id',            'display', 'variation_feature');
    denormalized($self->dba, 'variation_feature',    'variation_feature_id',    'display', 'transcript_variation');
  }
}

1;

