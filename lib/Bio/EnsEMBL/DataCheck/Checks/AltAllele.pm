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

package Bio::EnsEMBL::DataCheck::Checks::AltAllele;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'AltAllele',
  DESCRIPTION => 'Alt allele group members map back to the same chromosome',
  GROUPS      => ['core', 'geneset'],
  DB_TYPES    => ['core'],
};

sub tests {
  my ($self) = @_;

  my $aaga = $self->dba->get_adaptor('AltAlleleGroup');
  my $aags = $aaga->fetch_all();

  my @multiple_chromosomes = ();

  foreach my $aag (@$aags) {
    my $genes = $aag->get_all_Genes();
    my %chrs;
    foreach (@$genes) {
      if ($_->slice->is_reference) {
        $chrs{$_->slice->seq_region_name}++;
      } else {
        foreach my $ae ( @{ $_->slice->get_all_AssemblyExceptionFeatures } ) {
          $chrs{$ae->alternate_slice->seq_region_name}++;
        }
      }
    }
    push @multiple_chromosomes, $aag->dbID if scalar(keys(%chrs)) > 1;
  }

  my $desc = 'Members of alt_allele groups map back to the same chromosome';
  is(scalar(@multiple_chromosomes), 0, $desc) or
    diag('AltAlleleGroup IDs: ' . join(',', @multiple_chromosomes));
}

1;
