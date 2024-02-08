=head1 LICENSE

Copyright [2018-2024] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::MetaKeyConditional;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MetaKeyConditional',
  DESCRIPTION => 'Conditional meta keys exist if the data requires them',
  GROUPS      => ['core', 'brc4_core', 'meta', 'variation'],
  DB_TYPES    => ['core', 'variation'],
  TABLES      => ['meta']
};

sub tests {
  my ($self) = @_;

  if ($self->dba->group eq 'core') {
    # assembly.ucsc_alias is a candidate for a conditional check,
    # but not sure how best to define the condition...
    $self->collection_db_name();
    $self->gencode_species();
    $self->havana_species();
    $self->projected_transcripts();
    $self->repeat_analysis();
    $self->strain_type();
  } elsif ($self->dba->group eq 'variation') {
    $self->has_polyphen();
    $self->has_sift();
  }
}

sub collection_db_name {
  my ($self) = @_;

  SKIP: {
    skip 'Not a collection database', 1 unless $self->dba->is_multispecies;

    my $desc = "'species.db_name' meta_key exists";
    my $mca = $self->dba->get_adaptor('MetaContainer');
    my $values = $mca->list_value_by_key('species.db_name');
    ok(scalar @$values, $desc);
  }
}

sub gencode_species {
  my ($self) = @_;

  my %gencode_species = (
    homo_sapiens => 1,
    mus_musculus => 1,
  );

  SKIP: {
    skip 'Not a GENCODE species', 1 unless exists $gencode_species{$self->species};

    my $mca = $self->dba->get_adaptor('MetaContainer');

    my $assembly = $mca->single_value_by_key('assembly.default');
    skip 'Not applicable to GRCh37', 1 if $assembly eq 'GRCh37';

    my @meta_keys = ('gencode.version');
    foreach my $meta_key (@meta_keys) {
      my $desc = "'$meta_key' meta_key exists";
      my $values = $mca->list_value_by_key($meta_key);
      ok(scalar @$values, $desc);
    }

    my $old_dba = $self->get_old_dba();
    my $old_mca = $old_dba->get_adaptor('MetaContainer');

    my $cur_geneset_update = $mca->single_value_by_key('genebuild.last_geneset_update');
    my $old_geneset_update = $old_mca->single_value_by_key('genebuild.last_geneset_update');
    my $cur_gencode_version = $mca->single_value_by_key('gencode.version');
    my $old_gencode_version = $old_mca->single_value_by_key('gencode.version');
    my $cur_datafreeze_date = $mca->single_value_by_key('genebuild.havana_datafreeze_date');
    my $old_datafreeze_date = $old_mca->single_value_by_key('genebuild.havana_datafreeze_date');

    if ($cur_geneset_update eq $old_geneset_update) {
      my $desc_1 = 'Same geneset as previous release, same GENCODE version';
      is($cur_gencode_version, $old_gencode_version, $desc_1);
      my $desc_2 = 'Same geneset as previous release, same HAVANA datafreeze date';
      is($cur_datafreeze_date, $old_datafreeze_date, $desc_2);
    } else {
      my $desc_1 = 'Updated geneset from previous release, updated GENCODE version';
      isnt($cur_gencode_version, $old_gencode_version, $desc_1);
      my $desc_2 = 'Updated geneset from previous release, updated HAVANA datafreeze date';
      isnt($cur_datafreeze_date, $old_datafreeze_date, $desc_2);
    }

    my $desc = 'Web data matches GENCODE version meta key';
    my $diag = 'Mismatched GENCODE version';
    my $sql = qq/
      SELECT logic_name, web_data FROM
        analysis INNER JOIN
        analysis_description USING (analysis_id)
      WHERE
        web_data LIKE '%GENCODE%' AND
        web_data NOT LIKE '%$cur_gencode_version%'
    /;
    is_rows_zero($self->dba, $sql, $desc, $diag);
  }
}

sub havana_species {
  my ($self) = @_;

  my %havana_species = (
    homo_sapiens => 1,
    mus_musculus => 1,
    rattus_norvegicus => 1,
    danio_rerio => 1,
  );

  SKIP: {
    skip 'Not a HAVANA species', 1 unless exists $havana_species{$self->species};

    my @meta_keys = ('assembly.long_name', 'genebuild.havana_datafreeze_date');
    foreach my $meta_key (@meta_keys) {
      my $desc = "'$meta_key' meta_key exists";
      my $mca = $self->dba->get_adaptor('MetaContainer');
      my $values = $mca->list_value_by_key($meta_key);
      ok(scalar @$values, $desc);
    }
  }
}

sub projected_transcripts {
  my ($self) = @_;

  SKIP: {
    my $aa = $self->dba->get_adaptor('Analysis');
    my $analyses = $aa->fetch_all_by_feature_class('ProteinAlignFeature');
    my %logic_names = map { $_->logic_name => 1 } @$analyses;

    skip 'No projected transcripts', 1 unless exists $logic_names{'projected_transcript'};

    my $desc = "'genebuild.projection_source_db' meta_key exists";
    my $mca = $self->dba->get_adaptor('MetaContainer');
    my $values = $mca->list_value_by_key('genebuild.projection_source_db');
    ok(scalar @$values, $desc);
  }
}

sub repeat_analysis {
  my ($self) = @_;

  SKIP: {
    # For collection dbs, we might have an analysis in the database,
    # but no associated features for some of the species.
    # To save the significant overhead of retrieving all repeat features
    # in order to do a count, use SQL rather than API.
    my $helper = $self->dba->dbc->sql_helper;
    my $species_id = $self->dba->species_id;
    my $mca = $self->dba->get_adaptor('MetaContainer');
    my @rep_list = ();
    if ($mca->get_division eq 'EnsemblVertebrates') {
      @rep_list = qw("repeatmask_repeatmodeler" "repeatdetector");
    }
    else {
      @rep_list = qw("repeatmask_repeatmodeler");
    }
    my $to_skip = join(", ", @rep_list);

    my $sql = qq/
      SELECT logic_name FROM
        coord_system INNER JOIN
        seq_region USING (coord_system_id) INNER JOIN
        repeat_feature USING (seq_region_id) INNER JOIN
        analysis USING (analysis_id)
      WHERE
        species_id = $species_id
        AND logic_name NOT IN ($to_skip)
      GROUP BY
        logic_name
      ORDER BY logic_name
      COLLATE latin1_bin
    /;
    my @logic_names = @{$helper->execute_simple(-SQL => $sql)};

    skip 'No repeat features', 1 unless scalar(@logic_names);

    my $desc = "'repeat.analysis' meta_keys exist for appropriate repeat analyses";
    my @values = sort @{ $mca->list_value_by_key('repeat.analysis') };
    is_deeply(\@values, \@logic_names, $desc);
  }
}

sub strain_type {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor('MetaContainer');
  my $strain_group = $mca->list_value_by_key('species.strain_group');

  SKIP: {
    skip 'No strain group', 1 unless scalar @$strain_group;

    my $desc = "'strain.type' meta_key exists";
    my $strain_type = $mca->list_value_by_key('strain.type');
    ok(scalar @$strain_type, $desc);
  }
}

sub has_polyphen {
  my ($self) = @_;

  my %polyphen_species = (
    homo_sapiens => 1,
  );

  SKIP: {
    skip 'Polyphen data not expected', 1 unless exists $polyphen_species{$self->species};

    my $desc = "'polyphen_version' meta_key exists";
    my $mca = $self->dba->get_adaptor('MetaContainer');
    my $values = $mca->list_value_by_key('polyphen_version');
    ok(scalar @$values, $desc);
  }
}

sub has_sift {
  my ($self) = @_;

  my %sift_species = (
    homo_sapiens => 1,
  );

  SKIP: {
    skip 'Sift data not expected', 1 unless exists $sift_species{$self->species};

    my $desc = "'sift_version' meta_key exists";
    my $mca = $self->dba->get_adaptor('MetaContainer');
    my $values = $mca->list_value_by_key('sift_version');
    ok(scalar @$values, $desc);
  }
}

1;
