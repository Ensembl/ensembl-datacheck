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

package Bio::EnsEMBL::DataCheck::Checks::CheckWGACoverageStats;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::Utils::SqlHelper;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckWGACoverageStats',
  DESCRIPTION    => 'The number of rows for WGA coverage have not dropped from previous release',
  GROUPS         => ['compara', 'compara_gene_trees'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['compara'],
  TABLES         => ['homology']
};

sub tests {
  my ($self) = @_;
  my $prev_dba = $self->get_old_dba;

  my $curr_helper = $self->dba->dbc->sql_helper;
  my $prev_helper = $prev_dba->dbc->sql_helper;

  my $sql = qq/
    SELECT description, COUNT(*) 
      FROM homology 
    WHERE wga_coverage IS NOT NULL 
      GROUP BY description
  /;

  my $prev_results = $prev_helper->execute_into_hash( -SQL => $sql );
  my $curr_results = $curr_helper->execute_into_hash( -SQL => $sql );

  foreach my $type ( keys %$prev_results ) {
    my $desc = "There are the same number of wga_coverage populated rows between releases for $type";
    cmp_ok( $curr_results->{$type} // 0, ">=", $prev_results->{$type}, $desc );
  }

  unless (%$prev_results) {
    plan skip_all => "No MLSSs to test in this database";
  }
}

1;

