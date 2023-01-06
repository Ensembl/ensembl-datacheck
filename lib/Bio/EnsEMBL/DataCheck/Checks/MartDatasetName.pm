=head1 LICENSE

Copyright [2018-2023] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::MartDatasetName;

use warnings;
use strict;
use JSON qw(decode_json);

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use LWP::UserAgent;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'MartDatasetName',
  DESCRIPTION    => 'Check that the given core database mart dataset name is not exceeding MySQL limit of 64 chars and that they are unique accross all the divisions (except Bacteria)',
  GROUPS         => ['core','biomart'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['meta'],
  PER_DB         => 1
};

sub skip_tests {
  my ($self) = @_;

  if ( $self->dba->is_multispecies ) {
    return (1, 'No collection databases in mart');
  }

  my $mca = $self->dba->get_adaptor('MetaContainer');
  my $division = $mca->get_division;
  my $production_name = $mca->get_production_name;
  my $schema_version = $mca->get_schema_version;

  if ($division =~ '/EnsemblVertebrates|EnsemblMetazoa|EnsemblPlants/') {
    my $mart_species = mart_species($division, $schema_version);
    if (!grep( /$production_name/, @$mart_species) ){
      return (1, 'No mart for this species');
    }
  }
}

sub tests {
  my ($self) = @_;

  # If dataset is longer than 18 characters, we won't be able to
  # generate gene mart tables, because this will make them exceed
  # the MySQL table name limit of 64 characters.
  my $desc_1 = 'Mart abbreviation of species name is less than 19 characters';
  my $dbname = $self->dba->dbc->dbname;
  my $mart_dataset = generate_dataset_name_from_db_name($dbname);
  cmp_ok(length($mart_dataset), '<=', 18, $desc_1) ||
    diag("\"$mart_dataset\" is too long, contact the Production team");

  my $desc_2 = 'Mart abbreviation of species name does not already exist';
  my $mca = $self->dba->get_adaptor('MetaContainer');
  my $division = $mca->get_division;
  my $production_name = $mca->get_production_name;
  my $schema_version = $mca->get_schema_version;

  my $metadata_dba = $self->get_dba('multi', 'metadata');
  my $gia  = $metadata_dba->get_GenomeInfoAdaptor();
  my $dria = $metadata_dba->get_DataReleaseInfoAdaptor();

  my $release_info = $dria->fetch_by_ensembl_release($schema_version);
  if (! defined $release_info) {
    $release_info = $dria->fetch_by_ensembl_release($schema_version - 1);
  }
  $gia->data_release($release_info);

  # The vertebrate mart is on its own server, so no need to check
  # other divisions; all non-vertebrates share a server, so need
  # to be cross-checked, apart from bacteria, which are not in marts.
  my @divisions;
  if ($division eq 'EnsemblVertebrates'){
    push @divisions, $division;
  } else {
    my %divisions = map { $_ => 1 } @{ $gia->list_divisions };
    delete $divisions{'EnsemblBacteria'};
    delete $divisions{'EnsemblVertebrates'};
    @divisions = keys %divisions;
  }

  my @name_clashes;
  foreach (@divisions) {
    my $genomes = $gia->fetch_all_by_division($_);
    foreach my $genome (@$genomes){
      next if ($genome->name eq $production_name);

      my $genome_mart_dataset = generate_dataset_name_from_db_name($genome->dbname);

      if ($mart_dataset eq $genome_mart_dataset) {
        push @name_clashes,
          "\"$mart_dataset\" is used for ".$genome->name." (".$genome->dbname.")";
      }
    }
  }

  is(scalar(@name_clashes), 0, $desc_2) || diag explain \@name_clashes;
}

sub mart_species {
	my ($division, $schema_version) = @_;
  $division =~ s/Ensembl//;
  $division = lc($division);

  my $url_base = 'https://raw.githubusercontent.com/Ensembl/ensembl-compara';
  my $url_file = "conf/${division}/allowed_species.json";

  my $branch_url = "${url_base}/release/$schema_version/$url_file";
  my $main_url = "${url_base}/main/$url_file";
  my $mart_species = parse_config_file($branch_url, $main_url);

  return $mart_species;
}

sub parse_config_file {
  my ($branch_url, $main_url) = @_;

  my $ua  = LWP::UserAgent->new();

  my $req = HTTP::Request->new( GET => $branch_url );
  my $res = $ua->request($req);

  my $json;
  if ( $res->is_success ) {
    $json = $res->content;
  } else {
    $req = HTTP::Request->new( GET => $main_url );
    $res = $ua->request($req);

    if ( $res->is_success ) {
      $json = $res->content;
    } else {
      die( "Could not retrieve $branch_url or $main_url: " . $res->status_line );
    }
  }

  return decode_json($json);
}

sub generate_dataset_name_from_db_name {
  my ($database) = @_;

  $database =~ m/^(.)[^_]+_?([a-z0-9])?[a-z0-9]+?_([a-z0-9]+)_[a-z]+_[0-9]+_?[0-9]+?_[0-9]+$/;
  my $dataset = defined $2 ? "$1$2$3" : "$1$3";

  return $dataset;
}

1;
