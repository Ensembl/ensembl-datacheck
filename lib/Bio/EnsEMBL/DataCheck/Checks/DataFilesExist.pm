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

package Bio::EnsEMBL::DataCheck::Checks::DataFilesExist;

use warnings;
use strict;

use File::Spec::Functions qw/catdir/;
use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'DataFilesExist',
  DESCRIPTION => 'Data files are defined where necessary, and exist on the filesystem',
  GROUPS      => ['funcgen'],
  DB_TYPES    => ['funcgen'],
  FORCE       => 1
};

sub tests {
  my ($self) = @_;

  $self->alignment_has_bigwig();
  $self->segmentation_file_has_bigbed();
  $self->data_files_exist();
}

sub alignment_has_bigwig {
  my ($self) = @_;

  my $desc = 'Peak-calling alignment files are defined';
  my $diag = 'Missing BIGWIG file';
  my $sql  = q/
    SELECT
      a.alignment_id, 
      a.name
    FROM
      alignment a INNER JOIN
      peak_calling pc ON (
        pc.signal_alignment_id = a.alignment_id OR
        pc.control_alignment_id = a.alignment_id
      ) LEFT OUTER JOIN
      (
        SELECT data_file_id FROM data_file
        WHERE
          table_name = 'alignment' AND
          file_type = 'BIGWIG'
      ) df ON a.bigwig_file_id = df.data_file_id
    WHERE
      df.data_file_id IS NULL
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

sub segmentation_file_has_bigbed {
  my ($self) = @_;

  my $desc = 'Segmentation files are defined';
  my $diag = 'Missing BIGBED file';
  my $sql  = q/
    SELECT
      sf.segmentation_file_id, 
      sf.name
    FROM
      segmentation_file sf INNER JOIN
      regulatory_build rb USING (regulatory_build_id) LEFT OUTER JOIN
      (
        SELECT table_id FROM data_file
        WHERE
          table_name = 'segmentation_file' AND
          file_type = 'BIGBED'
      ) df ON sf.segmentation_file_id = df.table_id
    WHERE
      rb.is_current = 1 AND
      df.table_id IS NULL
  /;
  is_rows_zero($self->dba, $sql, $desc, $diag);
}

sub data_files_exist {
  my ($self) = @_;

  if ( ! (defined $self->data_file_path && -e $self->data_file_path) ) {
    die "Data file directory must be set as 'data_file_path' attribute";
  }

  my $path = $self->species_assembly_path($self->data_file_path);

  my $data_file_sql = q/
    SELECT table_name, path FROM data_file
    WHERE file_type IN ('BIGWIG', 'BIGBED')
  /;
  my $helper = $self->dba->dbc->sql_helper;
  my $data_files = $helper->execute(-SQL => $data_file_sql);

  my %table_names;
  my %missing_files;
  foreach (@$data_files) {
    my $table_name = $_->[0];
    $table_names{$table_name}++;

    # Don't need to check for undef $file value, db schema doesn't allow it.
    my $file = $_->[1];
    my $data_file = catdir($path, $file);
    if (! -e $data_file) {
      push @{$missing_files{$table_name}}, $data_file;
    }
  }

  foreach my $table_name (keys %table_names) {
    my $desc = "All $table_name data files exist";
    ok(!exists($missing_files{$table_name}), $desc); #||
      #diag explain $missing_files{$table_name};
  }
}

sub species_assembly_path {
  my ($self, $data_file_path) = @_;

  my $species = $self->species;
  my $core_dba = $self->get_dna_dba;
  my $meta = $core_dba->get_MetaContainer;
  my $assembly_default = $meta->single_value_by_key('assembly.default');

  return catdir($data_file_path, $species, $assembly_default);
}

1;
