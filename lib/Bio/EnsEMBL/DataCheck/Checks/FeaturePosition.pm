=head1 LICENSE

Copyright [2018] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::FeaturePosition;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
    NAME        => 'FeaturePosition',
    DESCRIPTION => 'Checks if features lie within bounds of seq_region i.e. start >=0 and end <= seq_region length.',
    GROUPS      => [ 'corelike_handover' ],
    DB_TYPES    => [ 'funcgen' ]
};

sub tests {
  my ($self) = @_;

  my $dna_dba = $self->get_dna_dba();
  my $mapper = sub {
    my ($row, $value) = @_;
    my %row = (
        region_name   => $$row[1],
        region_length => $$row[2]
    );
    return \%row;
  };
  # process with db is not master
  my $sql_regions = q/
    SELECT  seq_region_id,
            seq_region.name,
            `length`
    FROM    seq_region
    JOIN    seq_region_attrib USING (seq_region_id)
    JOIN    attrib_type USING (attrib_type_id)
    WHERE   code = "toplevel"
  /;

  my $helper = $dna_dba->dbc->sql_helper;
  my %regions = %{$helper->execute_into_hash(-SQL => $sql_regions, -CALLBACK => $mapper)};
  my @feature_tables = ("peak", "regulatory_feature", "motif_feature", "external_feature", "mirna_target_feature");

  foreach my $feature_table (@feature_tables) {
    my $desc_feature_ok = "No " . $feature_table . "s exceeding seq_region bounds";
    my $desc_feature_pos = "";
    my $feature_count = 0;
    foreach my $region_id (keys %regions) {
      my %region_info = %{$regions{$region_id}};
      # print 'region_id' . $region_id . "\n";
      my $region_name = $region_info{'region_name'};
      my $region_length = $region_info{'region_length'};
      # print $region_info{'region_name'} . "\n";
      # print $region_info{'region_length'} . "\n";
      # print $feature_table . "\n";
      my $feature_pos_sql;
      if ($region_name eq "regulatory_feature") {
        $feature_pos_sql = qq/
          SELECT COUNT(${feature_table}_id)
          FROM    $feature_table
          WHERE   seq_region_id= $region_id
          AND     ((seq_region_start - bound_start_length) <= 0
          OR      (seq_region_end + bound_end_length) > $region_length)
          /;

      }
      else {
        $feature_pos_sql = qq/
          SELECT COUNT(${feature_table}_id)
          FROM    $feature_table
          WHERE   seq_region_id= $region_id
          AND     (seq_region_start <= 0 OR seq_region_end > $region_length)
          /;
      }
      $feature_count += sql_count($self->dba, $feature_pos_sql);
    }
    $desc_feature_pos = "Found " . $feature_count . " for " . $feature_table . "s exceeding seq_region bounds";
    if ($feature_count > 0) {
      fail($desc_feature_pos);
    }
    else {
      ok($desc_feature_ok);
    }
  }
}

1;

