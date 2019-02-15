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

package Bio::EnsEMBL::DataCheck::Checks::MetaKeyConditional;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MetaKeyConditional',
  DESCRIPTION => 'Conditional meta keys exist if the data requires them',
  GROUPS      => ['core', 'meta', 'variation'],
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

    my @meta_keys = ('gencode.version');
    foreach my $meta_key (@meta_keys) {
      my $desc = "'$meta_key' meta_key exists";
      my $mca = $self->dba->get_adaptor('MetaContainer');
      my $values = $mca->list_value_by_key($meta_key);
      ok(scalar @$values, $desc);
    }
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
    my $aa = $self->dba->get_adaptor('Analysis');
    my $analyses = $aa->fetch_all_by_feature_class('RepeatFeature');
    my @logic_names = sort map { $_->logic_name } @$analyses;

    skip 'No repeat features', 1 unless scalar(@logic_names);

    my $desc = "'repeat.analysis' meta_keys exist for every repeat analysis";
    my $mca = $self->dba->get_adaptor('MetaContainer');
    my @values = sort @{ $mca->list_value_by_key('repeat.analysis') };
    is_deeply(\@values, \@logic_names, $desc);
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
