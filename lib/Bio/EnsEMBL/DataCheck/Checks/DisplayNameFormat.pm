=head1 LICENSE

Copyright [2018-2021] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::DisplayNameFormat;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'DisplayNameFormat',
  DESCRIPTION => 'For Rapid Release, the display name must be a specific format',
  GROUPS      => ['rapid_release'],
  DB_TYPES    => ['core'],
  TABLES      => ['meta']
};

sub tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");

  # Check that the format of the display name conforms to expectations.
  my $format = '[A-Za-z0-9 ]+ \([A-Za-z0-9 ]+\) \- GCA_\d+\.\d+';

  my $desc = "Display name has correct format";
  my $display_name = $mca->single_value_by_key('species.display_name');
  like($display_name, qr/^$format$/, $desc);
}

1;
