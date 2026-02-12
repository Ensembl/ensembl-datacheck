=head1 LICENSE

Copyright [2018-2025] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::SpeciesTagConsistency;

use warnings;
use strict;

use Bio::EnsEMBL::ApiVersion qw(software_version);

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'SpeciesTagConsistency',
  DESCRIPTION    => 'Consistency of reference and non-reference species tags across releases',
  GROUPS         => ['compara'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['compara'],
  TABLES         => ['method_link', 'method_link_species_set', 'method_link_species_set_tag'],
  PER_DB         => 1
};

sub tests {
  my ($self) = @_;
  my $prev_dba = $self->get_old_dba;

  my $curr_helper = $self->dba->dbc->sql_helper;
  my $prev_helper = $prev_dba->dbc->sql_helper;

  my $curr_release = software_version();

  my $rerun_mlss_sql = qq/
    SELECT method_link_species_set_id
      FROM method_link_species_set_tag
    WHERE
      tag = 'rerun_in_$curr_release';
  /;
  my $rerun_mlss_ids = $curr_helper->execute_simple( -SQL => $rerun_mlss_sql );
  my %rerun_mlss_id_set = map { $_ => 1 } @{$rerun_mlss_ids};

  my $species_tag_sql = q/
    SELECT method_link_species_set_id, tag, value
      FROM method_link_species_set_tag
    WHERE
      tag IN ('reference_species', 'non_reference_species');
  /;

  my $prev_results = $prev_helper->execute( -SQL => $species_tag_sql );
  my %prev_species_tags;
  foreach my $row (@{$prev_results}) {
    my ($mlss_id, $tag, $value) = @{$row};
    $prev_species_tags{$mlss_id}{$tag} = $value;
  }

  my $curr_results = $curr_helper->execute( -SQL => $species_tag_sql );
  my %curr_species_tags;
  foreach my $row (@{$curr_results}) {
    my ($mlss_id, $tag, $value) = @{$row};
    $curr_species_tags{$mlss_id}{$tag} = $value;
  }

  my @reused_mlss_ids = grep { exists $prev_species_tags{$_} && ! exists $rerun_mlss_id_set{$_} } keys %curr_species_tags;

  @reused_mlss_ids = sort { $a <=> $b } @reused_mlss_ids;

  my $mlss_dba = $self->dba->get_MethodLinkSpeciesSetAdaptor();
  foreach my $mlss_id (@reused_mlss_ids) {
    my $mlss = $mlss_dba->fetch_by_dbID($mlss_id);
    my $mlss_name = $mlss->name;
    foreach my $tag ('reference_species', 'non_reference_species') {
      if (exists $curr_species_tags{$mlss_id}{$tag} && exists $prev_species_tags{$mlss_id}{$tag}) {
        my $prev_tag_value = $prev_species_tags{$mlss_id}{$tag};
        my $curr_tag_value = $curr_species_tags{$mlss_id}{$tag};
        my $desc_1 = sprintf("MLSS '%s' (mlss_id:%d) '%s' tag consistency", $mlss->name, $mlss_id, $tag);
        is($curr_tag_value, $prev_tag_value, $desc_1);
      }
    }
  }
}

1;

