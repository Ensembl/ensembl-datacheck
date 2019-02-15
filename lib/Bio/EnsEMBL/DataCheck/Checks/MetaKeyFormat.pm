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

package Bio::EnsEMBL::DataCheck::Checks::MetaKeyFormat;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'MetaKeyFormat',
  DESCRIPTION => 'Meta values are correctly formatted and linked',
  GROUPS      => ['core', 'meta', 'variation'],
  DB_TYPES    => ['core', 'variation'],
  TABLES      => ['meta']
};

sub tests {
  my ($self) = @_;

  my $mca = $self->dba->get_adaptor("MetaContainer");

  # Check that the format of meta_values conforms to expectations.
  my %formats = (
    'assembly.accession'             => 'GCA_\d+\.\d+',
    'assembly.date'                  => '\d{4}-\d{2}',
    'assembly.default'               => '[\w\.\-]+',
    'genebuild.id'                   => '\d+',
    'genebuild.initial_release_date' => '\d{4}-\d{2}',
    'genebuild.last_geneset_update'  => '\d{4}-\d{2}',
    'genebuild.method'               => '(full_genebuild|projection_build|import|mixed_strategy_build|external_annotation_import)',
    'genebuild.start_date'           => '\d{4}\-\d{2}\-\S+',
    'patch'                          => '[^\n]+',
    'sample.location_param'          => '\w+:\d+\-\d+',
    'species.division'               => 'Ensembl(Bacteria|Fungi|Metazoa|Plants|Protists|Vertebrates)',
    'species.production_name'        => '[a-z0-9]+_[a-z0-9_]+',
    'species.scientific_name'        => '[A-Z][a-z0-9]+ [\w \(\)]+',
    'species.url'                    => '[A-Z][a-z0-9]+_[A-Za-z0-9_]+',
    'web_accession_type'             => '(GenBank Assembly ID|EMBL\-Bank|WGS Master)',
    'web_accession_source'           => '(NCBI|ENA|DDBJ)',
  );

  foreach my $meta_key (sort keys %formats) {
    my $desc   = "Value for $meta_key has correct format";
    my $format = $formats{$meta_key};
    my $values = $mca->list_value_by_key($meta_key);
    SKIP: {
      skip "No $meta_key defined", 1 unless scalar(@$values);
      foreach my $value (@$values) {
        like($value, qr/^$format$/, $desc);
      }
    }
  }

  # For meta_values that are from other parts of the database,
  # ensure that the data actually exists.
  if ($self->dba->group eq 'core') {
    fk($self->dba, 'meta', 'meta_value', 'gene', 'stable_id', 'meta_key = "sample.gene_param"');
    fk($self->dba, 'meta', 'meta_value', 'transcript', 'stable_id', 'meta_key = "sample.transcript_param"');
    my $value = $mca->single_value_by_key('sample.location_param');
    SKIP: {
      my $desc = 'Value for sample.location_param is valid';
      skip "No sample.location_param defined", 1 unless defined $value;
      my $sa = $self->dba->get_adaptor("Slice");
      my $slice = $sa->fetch_by_toplevel_location($value);
      ok(defined($slice), $desc);
    }
  } elsif ($self->dba->group eq 'variation') {
    fk($self->dba, 'meta', 'meta_value', 'population', 'population_id', 'meta_key = "pairwise_ld.default_population"');
    fk($self->dba, 'meta', 'meta_value', 'sample', 'name', 'meta_key = "sample.default_strain"');
  }
}

1;
