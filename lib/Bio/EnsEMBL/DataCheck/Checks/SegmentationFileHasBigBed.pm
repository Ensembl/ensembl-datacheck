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

package Bio::EnsEMBL::DataCheck::Checks::SegmentationFileHasBigBed;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SegmentationFileHasBigBed',
  DESCRIPTION => 'Check that every segmentation_file entry which has been used in the current Regulatory Build is linked to a BIGBED entry in the data_file table and exists on disk',
  GROUPS      => ['funcgen', 'regulatory_build'],
  DB_TYPES    => ['funcgen'],
  TABLES      => ['regulatory_build','regulatory_feature'],
};

sub skip_tests {
  my ($self) = @_;

  my $sql = q/
    SELECT COUNT(name) FROM regulatory_build 
    WHERE is_current=1
  /;

  if (! sql_count($self->dba, $sql) ) {
    return (1, 'The database has no regulatory build');
  }
}

sub build_segmentation_base_file_path {
  my ($self,$data_file_path) = @_;
  my $species = $self->species;
  my $core_dba = $self->get_dna_dba();
  my $meta = $core_dba->get_MetaContainer();
  my $assembly_default = $meta->single_value_by_key('assembly.default');
  my $base_file_path = "$data_file_path/$species/$assembly_default/";
  return $base_file_path;
}

sub tests {
  my ($self) = @_;
  my $data_file_path = '/nfs/panda/ensembl/production/ensemblftp/data_files/';
  my $table_name = 'segmentation_file';
  my $file_type = 'BIGBED';
  my $base_file_path = $self->build_segmentation_base_file_path($data_file_path);
  my $helper = $self->dba->dbc->sql_helper;
  my $missing_file_for_segmentation_file_id = 0;
  my $sql = qq/
      SELECT
        segmentation_file_id, 
        segmentation_file.name
      FROM
        segmentation_file JOIN
        regulatory_build USING(regulatory_build_id)
      WHERE regulatory_build.is_current=1
    /;
   my $segmentation_files = $helper->execute_into_hash(-SQL => $sql);
   foreach my $segmentation_file_id (keys %$segmentation_files) {
     my $sql2 = q/
        SELECT 
          path
        FROM
          data_file
        WHERE
          table_name = ? AND
          file_type = ? AND
          table_id = ?
     /;
     my $file_path = $helper->execute_simple(-SQL => $sql2,-PARAMS => [$table_name,$file_type,$segmentation_file_id])->[0];
     my $desc = "$file_type file entry found in the data_file table for $table_name with name ".$segmentation_files->{$segmentation_file_id}." and id $segmentation_file_id";
     ok(defined $file_path, $desc);
     if (defined $file_path){
       my $segmentation_file = $base_file_path."$file_path";
       ok(-e $segmentation_file,"$segmentation_file exists on disk") or diag("$segmentation_file doest not exist on the disk for segmentation id $segmentation_file_id and name ".$segmentation_files->{$segmentation_file_id});
     }
   }
}
1;
