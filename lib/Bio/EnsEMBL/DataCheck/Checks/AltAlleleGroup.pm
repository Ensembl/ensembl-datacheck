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

package Bio::EnsEMBL::DataCheck::Checks::AltAlleleGroup;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'AltAlleleGroup',
  DESCRIPTION => 'No alt_allele_group has more than one gene from the primary assembly',
  GROUPS      => ['core', 'geneset'],
  DB_TYPES    => ['core']
};

sub tests {
  my ($self) = @_;

  my $aaga = $self->dba->get_adaptor('AltAlleleGroup');
  my $aags = $aaga->fetch_all();

  my @multiple_reference = ();

  foreach my $aag (@$aags) {
    my $genes = $aag->get_all_Genes();
    my $reference = 0;
    foreach (@$genes) {
      $reference += $_->slice->is_reference;
    }
    push @multiple_reference, $aag->dbID if $reference > 1;
  }

  my $desc = 'No more than one gene in primary assembly linked to assembly groups';
  is(scalar(@multiple_reference), 0, $desc) or
    diag('AltAlleleGroup IDs: ' . join(',', @multiple_reference));
}

1;
