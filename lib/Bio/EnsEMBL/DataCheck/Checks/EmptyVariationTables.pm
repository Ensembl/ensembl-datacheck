=head1 LICENSE

Copyright [2018-2020] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::EmptyVariationTables;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'EmptyVariationTables',
  DESCRIPTION    => 'Variation tables are not empty',
  GROUPS         => ['variation'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['variation'],
  PER_DB         => 1
};

sub tests {
  my ($self) = @_;
  
  my $tables = $self->get_tables_to_check();
  foreach my $table (@$tables) {
    my $desc = "Table $table has rows";
    my $sql  = qq/
      SELECT COUNT(*)
      FROM $table
    /;
    is_rows_nonzero($self->dba, $sql, $desc);
  }
}

# The get_tables_to_check sub is based on getTablesToCheck in the HealtchCheck
# TO DO - replace with getting information on expected populated tables from 
# the meta table
sub get_tables_to_check {
  my ($self) = @_;
  
  my $species = $self->species;
  my %applicable_species;
    
  my $table_sql = q/
    SELECT TABLE_NAME
    FROM
      INFORMATION_SCHEMA.TABLES
    WHERE
      TABLE_SCHEMA = database() AND
      TABLE_TYPE = 'BASE TABLE'
  /;
  
  my $tables = $self->dba->dbc->sql_helper->execute_simple(-SQL => $table_sql);

  my $unused_tables = [qw/coord_system strain_gtype_poly/];
  
  # TODO review as protein_function_predictions available other species
  my $human_only_tables= [qw/allele_synonym
                            protein_function_predictions
                            protein_function_predictions_attrib 
                            phenotype associate_study 
                            translation_md5/];
                            
  my $set_tables = [qw/variation_set_structure/];
  
  my $sv_tables = [qw/study structural_variation
                    structural_variation_feature 
                    structural_variation_association 
                    structural_variation_sample 
                    variation_set_structural_variation 
                    failed_structural_variation/];
                    
  my $sample_tables = [qw/population_genotype
                         population_structure
                         population_synonym 
                         individual_synonym 
                         sample individual/];
                         
  my $regulatory_tables = [qw/motif_feature_variation
                             regulatory_feature_variation 
                             display_group/];
                             
  my $citation_tables = [qw/publication variation_citation/];
  
  # Remove the unused tables
  $tables = $self->remove_tables($tables, $unused_tables);

  # For species other than human remove human specific tables
  if ($species ne 'homo_sapiens') {
    $tables = $self->remove_tables($tables, $human_only_tables);
    $tables = $self->remove_tables($tables, $set_tables);
  }
  
  # Remove structural variation for species without SV
  my @species_with_SV = qw/
      bos_taurus 
      canis_familiaris
      danio_rerio
      equus_caballus
      homo_sapiens
      macaca_mulatta
      mus_musculus
      ovis_aries
      sus_scrofa
  /;
  
  %applicable_species = map { $_ => 1 } @species_with_SV;
  if ( ! exists $applicable_species{$self->species} ) {
    $tables = $self->remove_tables($tables, $sv_tables);
  }

  # Remove sample tables for species without sample data  
  my @species_without_samples = qw/
    anopheles_gambiae
    ornithorhynchus_anatinus
    tetraodon_nigroviridis
  /;
  %applicable_species = map { $_ => 1 } @species_without_samples;
  if (exists $applicable_species{$self->species} ) {
    $tables = $self->remove_tables($tables, $sample_tables);
  }

  # Remove requlatory tables for species without regulatory data
  if ($species !~ /(homo_sapiens|mus_musculus)/) {
    $tables = $self->remove_tables($tables, $regulatory_tables);
  }

  # Remove citation tables for species without citation database
  my @species_with_citations = qw/
     bos_taurus
     canis_lupus_familiaris
     capra_hircus
     danio_rerio
     equus_caballus
     gallus_gallus
     homo_sapiens
     mus_musculus
     ovis_aries
     rattus_norvegicus
     sus_scrofa
  /;
  %applicable_species = map { $_ => 1 } @species_with_citations;
  if ( ! exists $applicable_species{$self->species} ) {
    $tables = $self->remove_tables($tables, $citation_tables);
  }
  return $tables;
}

sub remove_tables {
  my ($self, $tables, $remove_tables) =  @_;

  my %remove_hash = map { $_ => 1 } @$remove_tables;
  my @complement = grep {! exists $remove_hash{$_}}  @$tables;
  return  [@complement];
}

1;
