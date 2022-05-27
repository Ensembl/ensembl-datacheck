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

package Bio::EnsEMBL::DataCheck::Checks::PhenotypeMultipleSeqRegions;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'PhenotypeMultipleSeqRegions',
  DESCRIPTION => 'Phenotypes on multiple seq regions',
  GROUPS      => ['variation'],
  DB_TYPES    => ['variation'],
  TABLES      => ['phenotype_feature']
};

sub skip_tests {
  my ($self) = @_;

  my $sql = 'SELECT COUNT(*) FROM phenotype_feature';
  my $count = sql_count($self->dba, $sql);
  if (! $count) {
    return (1, 'No phenotype_feature records');
  }
  if ($count == 1) {
    return (1, 'Only 1 phenotype_feature record');
  }

  my $desc_dna_dba = 'Core database found';
  my $dna_dba = $self->get_dna_dba();
  my $pass = ok(defined $dna_dba, $desc_dna_dba);

  # Note that if $pass is false, we will still execute the 'tests'
  # method; which is either not required, or will need to done again,
  # because the datacheck will fail. But it's complicated to do
  # otherwise, and it doesn't really matter for this datacheck,
  # because the query runs quickly.
  if ($pass) {
    my $mca = $dna_dba->get_adaptor("MetaContainer");
    my $division = $mca->get_division;

    if ($division ne 'EnsemblVertebrates') {
      return (1, "$division can have phenotypes on single seq region");
    }
  }
}

sub tests {
  my ($self) = @_;
  
  my $table = 'phenotype_feature';
  my $desc = "Table $table does not have 1 distinct seq region id";
  my $sql  = qq/
    SELECT COUNT(DISTINCT seq_region_id)
    FROM $table
  /;
  cmp_rows($self->dba, $sql, '!=', 1, $desc);
}

1;
