=head1 LICENSE

Copyright [2018-2020] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::CompareVariationFeatures;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CompareVariationFeatures',
  DESCRIPTION    => 'Compare variation feature counts between two databases, categorised by seq_region name',
  GROUPS         => ['compare_variation'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['variation'],
  TABLES         => ['seq_region', 'variation_feature']
};

sub tests {
  my ($self) = @_;

  SKIP: {
    my $old_dba = $self->get_old_dba();

    skip 'No old version of database', 1 unless defined $old_dba;
  
    my $curr_dna_dba = $self->get_dna_dba();
    my $old_core_dba = $self->get_old_dba(undef, 'core');

    my $desc_curr_core = 'Current core database found: '.$curr_dna_dba->dbc->dbname;
    my $curr_core_pass = ok(defined $curr_dna_dba, $desc_curr_core);

    my $desc_old_core = 'Old core database found: '.$old_core_dba->dbc->dbname;
    my $old_core_pass = ok(defined $old_core_dba, $desc_old_core);

    if ($curr_core_pass && $old_core_pass) {
      # Check the assembly version. Skip if not the same
      skip 'Different assemblies', 1
        unless $self->same_assembly($curr_dna_dba, $old_core_dba);

      my $desc = "Consistent variation feature counts by seq region name between ".
                 $self->dba->dbc->dbname.' and '.$old_dba->dbc->dbname;

      my $sql  = q/
        SELECT sr.name, COUNT(*)
        FROM variation_feature vf JOIN seq_region sr
          ON (vf.seq_region_id = sr.seq_region_id)
        GROUP BY sr.name
      /;
      row_subtotals($self->dba, $old_dba, $sql, undef, 1.00, $desc);
    }
  }
}

sub same_assembly {
  my ($self, $new_core_dba, $old_core_dba) = @_;

  # Get the assembly for the new_core_dba
  my $gca_new = $new_core_dba->get_adaptor("GenomeContainer");
  my $version_new = $gca_new->get_version();
  die('No assembly version') if (!$version_new);

  # Get the assembly for the old_core_dba
  my $gca_old = $old_core_dba->get_adaptor("GenomeContainer");
  my $version_old = $gca_old->get_version();
  die('No assembly version') if (!$version_old);

  if ($version_new eq $version_old) {
      return 1;
  } else {
      return 0;
  }
}

1;
