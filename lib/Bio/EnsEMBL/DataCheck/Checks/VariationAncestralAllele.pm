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

package Bio::EnsEMBL::DataCheck::Checks::VariationAncestralAllele;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'VariationAncestralAllele',
  DESCRIPTION => 'Ancestral alleles for COSMIC and ClinVar variant sources are present',
  DATACHECK_TYPE => 'advisory',
  GROUPS      => ['variation_import'],
  DB_TYPES    => ['variation'],
  TABLES      => ['variation_feature', 'source']
};

sub tests {
  my ($self) = @_;

  my $species = $self->species;
  
  SKIP: {
    skip 'Ancestral alleles from variant source COSMIC and ClinVar only expected for Homo sapiens', 1 unless $species =~ /homo_sapiens/;
      
    my $desc_COSMIC_exists = 'COSMIC variant source is present';
    my $sql_COSMIC_exists = qq(
       SELECT variation_feature.ancestral_allele
       FROM variation_feature,source
       WHERE source.name='COSMIC'
         AND variation_feature.source_id = source.source_id;
    );
    is_rows_nonzero($self->dba, $sql_COSMIC_exists, $desc_COSMIC_exists);
    
    my $is_COSMIC = $self->dba->dbc->sql_helper->execute(-SQL => $sql_COSMIC_exists);
    my $is_COSMIC_row_count = (@$is_COSMIC);
    
    SKIP: {
      skip 'Can only SELECT for COSMIC if data is present', 1 unless $is_COSMIC_row_count > 0;
      
      my $desc_ancestral_COSMIC = 'Check for missing ancestral alleles in COSMIC variant source';
      my $sql_ancestral_COSMIC  = qq(
        SELECT variation_feature.ancestral_allele
        FROM variation_feature,source
        WHERE source.name='COSMIC'
          AND variation_feature.source_id = source.source_id
          AND variation_feature.ancestral_allele IS NOT NULL;
      );
      is_rows_nonzero($self->dba, $sql_ancestral_COSMIC, $desc_ancestral_COSMIC);
     }
  
    my $desc_ClinVar_exists = 'ClinVar variant source is present';
    my $sql_ClinVar_exists = qq(
       SELECT variation_feature.ancestral_allele
       FROM variation_feature,source
       WHERE source.name='ClinVar'
         AND variation_feature.source_id = source.source_id;
    );
    is_rows_nonzero($self->dba, $sql_ClinVar_exists, $desc_ClinVar_exists);

    my $is_ClinVar = $self->dba->dbc->sql_helper->execute(-SQL => $sql_ClinVar_exists);
    my $is_ClinVar_row_count = (@$is_ClinVar);

    SKIP: {
      skip 'Can only SELECT for ClinVar if data is present', 1 unless $is_ClinVar_row_count > 0;
     
      my $desc_ancestral_ClinVar = 'Check for missing ancestral alleles in ClinVar variant source';
      my $sql_ancestral_ClinVar  = qq(
        SELECT variation_feature.ancestral_allele
        FROM variation_feature,source
        WHERE source.name='ClinVar'
          AND variation_feature.source_id = source.source_id
          AND variation_feature.ancestral_allele IS NOT NULL;
      );
      is_rows_nonzero($self->dba, $sql_ancestral_ClinVar, $desc_ancestral_ClinVar);
    }
  }
}

1;
