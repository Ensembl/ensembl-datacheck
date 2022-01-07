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

package Bio::EnsEMBL::DataCheck::Checks::ControlledAnalysis;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ControlledAnalysis',
  DESCRIPTION => 'Analysis descriptions and display settings are consistent with production database',
  GROUPS      => ['analysis_description', 'core', 'brc4_core', 'corelike'],
  DB_TYPES    => ['cdna', 'core', 'otherfeatures', 'rnaseq'],
  TABLES      => ['analysis', 'analysis_description'],
  PER_DB      => 1
};

sub skip_tests {
  my ($self) = @_;

  my $sql = 'SELECT COUNT(*) FROM analysis';

  if (! sql_count($self->dba, $sql) ) {
    return (1, 'No analyses.');
  }
}

sub tests {
  my ($self) = @_;

  # Scrunch rows returned by query into a hash for instructive comparisons.
  my $mapper = sub {
    my ($row, $value) = @_;
    my %row = (
      display_label => $$row[1],
      description   => $$row[2],
      displayable   => $$row[3],
      web_data      => $$row[4],
    );
    return \%row;
  };

  my $sql = qq/
    SELECT
      a.logic_name,
      ad.display_label,
      ad.description,
      ad.displayable,
      ad.web_data
    FROM
      analysis a LEFT OUTER JOIN
      analysis_description ad USING (analysis_id)
  /;
  my $helper   = $self->dba->dbc->sql_helper;
  my %analyses = %{ $helper->execute_into_hash(-SQL => $sql, -CALLBACK => $mapper) };

  my $prod_sql = qq/
    SELECT
      ad.logic_name,
      ad.display_label,
      ad.description,
      ad.displayable,
      wd.data
    FROM
      analysis_description ad LEFT OUTER JOIN
      web_data wd USING (web_data_id)
    WHERE 
      ad.is_current = 1
  /;
  my $prod_dba      = $self->get_dba('multi', 'production');
  my $prod_helper   = $prod_dba->dbc->sql_helper;
  my %prod_analyses = %{ $prod_helper->execute_into_hash(-SQL => $prod_sql, -CALLBACK => $mapper) };

  foreach my $logic_name (keys %analyses) {
    my $desc_1 = "Analysis '$logic_name' in production database";
    ok(exists $prod_analyses{$logic_name}, $desc_1);
    if (exists $prod_analyses{$logic_name}) {
      my $desc_2 = "Correct display properties for '$logic_name' analysis";
      is_deeply($analyses{$logic_name}, $prod_analyses{$logic_name}, $desc_2);
    }
  }
}

1;
