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

package Bio::EnsEMBL::DataCheck::Checks::EpigenomeHasSegmentationFile;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'EpigenomeHasSegmentationFile',
  DESCRIPTION => 'Check that every epigenome which is part of the current Regulatory Build has a segmentation file in the segmentation_file table',
  GROUPS      => ['funcgen_integrity', 'funcgen_Post_regulatory_build.'],
  DB_TYPES    => ['funcgen'],
  TABLES      => ['regulatory_build','regulatory_build_epigenome','epigenome'],
};

sub skip_tests {
  my ($self) = @_;

  my $sql = q/
    SELECT COUNT(name) FROM regulatory_build 
    WHERE is_current=true
  /;

  if (! sql_count($self->dba, $sql) ) {
    return (1, 'The database has no regulatory build');
  }
}

sub tests {
  my ($self) = @_;
    my $regulatory_build_adaptor = $self->dba->get_adaptor('RegulatoryBuild');
    my $regulatory_build = $regulatory_build_adaptor->fetch_current_regulatory_build;
    my $epigenomes_in_regulatory_build = $regulatory_build->get_all_Epigenomes;
    my $helper = $self->dba->dbc->sql_helper;
    my $pass = 1;
    my $desc = "All the epigenomes of the current Regulatory build have a segmentation file in the segmentation_file table";
    foreach my $epigenome (@$epigenomes_in_regulatory_build){
      my $sql  = q/
        SELECT segmentation_file_id FROM
          segmentation_file
        WHERE epigenome_id=? AND regulatory_build_id=?
        /;
      my $segmentation_file = $helper->execute_simple(-SQL => $sql, -PARAMS => [$epigenome->dbID(),$regulatory_build->dbID()])->[0];
      if (!defined $segmentation_file){
        diag('Epigenome '.$epigenome->display_label().' has no segmentation file in the segmentation_file table');
        $pass = 0;
      }
    }
    ok($pass == 1, $desc);

    # I think the code above is nicer when using the API but the MySQL access below is slightly faster (1-2s)
    #my $helper = $self->dba->dbc->sql_helper;
    #my $sql1 = q/SELECT regulatory_build_id FROM 
    #               regulatory_build 
    #            WHERE is_current=1/;
    #my $regulatory_build_id = $helper->execute_single_result(-SQL => $sql1);
    #my $sql2 = q/SELECT regulatory_build_epigenome_id, epigenome_id, ep.display_label FROM
    #                      regulatory_build_epigenome rbe JOIN
    #                      epigenome ep USING (epigenome_id) 
    #                    WHERE rbe.regulatory_build_id=?/;
    #my $epigenomes = $helper->execute(-SQL => $sql2, -USE_HASHREFS => 1, -PARAMS => [$regulatory_build_id] );
    #my $pass = 1;
    #my $desc = "All the epigenomes of the current Regulatory build have segmentation files";
    #foreach my $epigenome (@$epigenomes){
    #  my $sql3  = q/
    #    SELECT segmentation_file_id FROM
    #      segmentation_file
    #    WHERE epigenome_id=? AND regulatory_build_id=?
    #    /;
    #  my $segmentation_file = $helper->execute_simple(-SQL => $sql3, -PARAMS => [$epigenome->{epigenome_id},$regulatory_build_id])->[0];
    #  if (!defined $segmentation_file){
    #    diag('Epigenome '.$epigenome->{display_label}.' has no segmentation file in the segmentation_file table');
    #    $pass = 0;
    #  }
    #}
    #ok($pass == 1, $desc);
}

1;

