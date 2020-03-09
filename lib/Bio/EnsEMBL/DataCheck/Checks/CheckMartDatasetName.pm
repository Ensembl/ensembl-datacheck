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

package Bio::EnsEMBL::DataCheck::Checks::CheckMartDatasetName;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use MartUtils qw(generate_dataset_name_from_db_name);
use Bio::EnsEMBL::BioMart::Mart qw(genome_to_include);
use Bio::EnsEMBL::DataCheck::Utils qw/repo_location/;
use Bio::EnsEMBL::MetaData::Base qw(fetch_and_set_release);

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckMartDatasetName',
  DESCRIPTION    => 'Check that the given core database mart dataset name is not exceeding MySQL limit of 64 chars and that they are unique accross all the divisions (except Bacteria)',
  GROUPS         => ['core','biomart'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['meta']
};

sub tests {
  my ($self) = @_;
  SKIP: {
    my $dbname = $self->dba->dbc->dbname;
    my $mart_dataset = generate_dataset_name_from_db_name($dbname);
    my $mca = $self->dba->get_adaptor('MetaContainer');
    my $division = $mca->get_division;
    my $production_name = $mca->get_production_name;
    my $schema_version = $mca->get_schema_version;
    if ($division eq "EnsemblVertebrates"){
      my $repo_location = repo_location('ensembl-biomart');
      $repo_location =~ s/ensembl-biomart//;
      # Load species to include in the Vertebrates marts
      my $included_species = genome_to_include($division,$repo_location);
      if (!grep( /$production_name/, @$included_species) ){
        skip 'We dont build mart for this species', 1;
      }
    }
    # If dataset is longer than 18 char, we won't be able to generate gene mart tables
    # like dataset_gene_ensembl__protein_feature_superfamily__dm as this will exceed
    # the MySQL table name limit of 64 char.
    if (length($mart_dataset) > 18) {
      fail("$mart_dataset name is too long. Check with data team and remove this species $dbname from the include ini file\n");
      return;
    }
    my $metadata_dba = $self->registry->get_DBAdaptor('multi', 'metadata');
    my $gdba = $metadata_dba->get_GenomeInfoAdaptor();
    my $rdba = $metadata_dba->get_DataReleaseInfoAdaptor();
    my ($release,$release_info,$included_species);
    # Get the current release version
    ($rdba,$gdba,$release,$release_info) = fetch_and_set_release($schema_version,$rdba,$gdba);
    # Get list of divisions
    my $divisions = $gdba->list_divisions();
    foreach my $div (@$divisions){
      # Exlude Bacteria since we don't have a mart for them and they slow down this test
      next if $div eq "EnsemblBacteria";
      # Get all the genomes for the current release and division
      my $genomes = $gdba->fetch_all_by_division($div);
      foreach my $genome (@$genomes){
        # Skip this species
        if ($genome->name eq $production_name){
          next;
        }
        # Generate mart name using regexes
        my $other_species_mart_dataset_name = generate_dataset_name_from_db_name($genome->dbname);
        # If the species mart databaset clash with another species report it.
        if($mart_dataset eq $other_species_mart_dataset_name){
          fail("Mart dataset name $mart_dataset for $production_name ($dbname) clashes with ".$genome->name." (".$genome->dbname."). Please change production and database name");
          return;
        }
      }
    }
  }
  ok('Biomart tests all successful');
}

1;

