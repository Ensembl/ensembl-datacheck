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

package Bio::EnsEMBL::DataCheck::Checks::CheckMemberIDRange;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::Compara;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckMemberIDRange',
  DESCRIPTION    => 'All members are within the offset range for each genome_db',
  GROUPS         => ['compara_references'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['compara'],
  TABLES         => ['gene_member', 'seq_member']
};

sub tests {
  my ($self) = @_;
  my $dba    = $self->dba;
  my $helper = $dba->dbc->sql_helper;
  my $genome_dbs   = $dba->get_GenomeDBAdaptor->fetch_all();

  foreach my $genome_db ( sort { $a->dbID() <=> $b->dbID() } @$genome_dbs ) {
    my $genome_db_id = $genome_db->dbID();
    check_id_range($dba, "seq_member", "genome_db_id", $genome_db_id);
  }
}

1;

