=head1 LICENSE

Copyright [2018-2022] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CheckSequenceTable;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckSequenceTable',
  DESCRIPTION    => 'Check for sequence length and availability',
  GROUPS         => ['compara', 'compara_gene_trees', 'compara_references', 'compara_homology_annotation', 'compara_blastocyst'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['sequence']
};

sub tests {
  my ($self) = @_;
  my $dbc = $self->dba->dbc;

  my %conditions = (
    "All sequences in sequence table are viable" => "sequence=''",
    "The length in sequences is viable"          => "length<1",
    "The length matches the length of sequence"  => "length!=length(sequence)"
    );

  foreach my $desc ( keys %conditions ) {
    my $condition = $conditions{$desc};
    my $sql = qq/
      SELECT COUNT(*) 
        FROM sequence 
      WHERE $condition
    /;
    is_rows_zero( $dbc, $sql, $desc );
  }
  
}

1;
