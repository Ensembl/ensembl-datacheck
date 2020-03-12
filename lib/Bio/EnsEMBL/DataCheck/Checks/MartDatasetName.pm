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

package Bio::EnsEMBL::DataCheck::Checks::MartDatasetName;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/repo_location/;
use LWP::UserAgent;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'MartDatasetName',
  DESCRIPTION    => 'Check that the given core database mart dataset name is not exceeding MySQL limit of 64 chars and that they are unique accross all the divisions (except Bacteria)',
  GROUPS         => ['core','biomart'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['meta']
};

sub skip_tests {
  my ($self) = @_;
  if ( $self->dba->is_multispecies ) {
    return (1, 'We dont have collection databases in mart');
  }
  my $mca = $self->dba->get_adaptor('MetaContainer');
  my $division = $mca->get_division;
  my $production_name = $mca->get_production_name;
  my $schema_version = $mca->get_schema_version;
  if ($division eq "EnsemblVertebrates"){
    # Load species to include in the Vertebrates marts
    my $included_species = genome_to_include($division,$schema_version);
    if (!grep( /$production_name/, @$included_species) ){
      return (1, 'We dont build mart for this species');
    }
  }
}

sub tests {
  my ($self) = @_;
  my $dbname = $self->dba->dbc->dbname;
  my $mart_dataset = generate_dataset_name_from_db_name($dbname);
  my $mca = $self->dba->get_adaptor('MetaContainer');
  my $schema_version = $mca->get_schema_version;
  # If dataset is longer than 18 char, we won't be able to generate gene mart tables
  # like dataset_gene_ensembl__protein_feature_superfamily__dm as this will exceed
  # the MySQL table name limit of 64 char.
  cmp_ok(length($mart_dataset),"<=",18) || diag($self->species." mart name: $mart_dataset is too long, contact the Production team");
  my $metadata_dba = $self->get_dba('multi', 'metadata');
  my $gdba = $metadata_dba->get_GenomeInfoAdaptor();
  my $rdba = $metadata_dba->get_DataReleaseInfoAdaptor();
  # Get the current release version
  ($rdba,$gdba) = fetch_and_set_release($schema_version,$rdba,$gdba);
  my $species_division = $mca->get_division;
  my $divisions;
  # For Vertebrates we only want to check the other divisions since these are on a different server
  if ($species_division eq "EnsemblVertebrates"){
    push @$divisions, $species_division;
  }
  else{
    # Get list of divisions from metadata
    $divisions = $gdba->list_divisions();
  }
  my @name_clashes;
  foreach my $div (@$divisions){
    # Exlude Bacteria since we don't have a mart for them and they slow down this test
    next if $div eq "EnsemblBacteria";
    # Since vertebrates and non-vertebrates are on different servers at the moment we don't worry about clashes
    next if $div eq "EnsemblVertebrates" and $species_division ne "EnsemblVertebrates";
    # Get all the genomes for the current release and division
    my $genomes = $gdba->fetch_all_by_division($div);
    foreach my $genome (@$genomes){
      # Skip this species
      if ($genome->name eq $self->species){
        next;
      }
      # Generate mart name using regexes
      my $other_species_mart_dataset_name = generate_dataset_name_from_db_name($genome->dbname);
      # If the species mart databaset clash with another species report it.
      if($mart_dataset eq $other_species_mart_dataset_name){
        push @name_clashes,"Mart name is also $mart_dataset for ".$genome->name." (".$genome->dbname.")";
      }
    }
  }
  is(scalar(@name_clashes), 0, 'All Genomes have a unique mart name across divisions') || diag explain \@name_clashes;
}

#Generate a mart dataset name from a database name
sub generate_dataset_name_from_db_name {
    my ($database) = @_;
    ( my $dataset = $database ) =~ m/^(.)[^_]+_?([a-z0-9])?[a-z0-9]+?_([a-z0-9]+)_[a-z]+_[0-9]+_?[0-9]+?_[0-9]+$/;
    $dataset = defined $2 ? "$1$2$3" : "$1$3";
    return $dataset;
}

sub genome_to_include {
	my ($div,$schema_version) = @_;
	#Get both division short and full name from a division short or full name
	my ($division,$division_name)=process_division_names($div);
  my $included_species = parse_ini_file("https://raw.githubusercontent.com/Ensembl/ensembl-biomart/release/".$schema_version."/scripts/include_".$division.".ini");
	return $included_species;
}

=head2 process_division_names
  Description: Process the division name, and return both division like metazoa and division name like EnsemblMetazoa
  Arg        : division name or division short name
  Returntype : string
  Exceptions : none
  Caller     : Internal
  Status     : Stable
=cut
sub process_division_names {
  my ($div) = @_;
  my $division;
  my $division_name;
  #Creating the Division name EnsemblBla and division bla variables
  if ($div !~ m/[E|e]nsembl/){
    $division = $div;
    $division_name = 'Ensembl'.ucfirst($div) if defined $div;
  }
  else{
    $division_name = $div;
    $division = $div;
    $division =~ s/Ensembl//;
    $division = lc($division);
  }
  return ($division,$division_name)
}

=head2 fetch_and_set_release
  Description: fetch the right release for a release data Info adaptor and set it in the Genome Data Info Adaptor
  Arg        : release version
  Arg        : Release Data Info Adaptor
  Arg        : Genome Data Info Adaptor
  Returntype : adaptors and string
  Exceptions : none
  Caller     : Internal
  Status     : Stable
=cut
sub fetch_and_set_release {
  my ($release_version,$rdba,$gdba) = @_;
  my ($release_info,$release);
  if (defined $release_version){
    $release_info = $rdba->fetch_by_ensembl_genomes_release($release_version);
    if (!$release_info){
      $release_info = $rdba->fetch_by_ensembl_release($release_version);
      $release = $release_info->{ensembl_version};
    }
    else{
      $release = $release_info->{ensembl_genomes_version};
    }
    $gdba->data_release($release_info);
  }
  else{
    $release_info = $rdba->fetch_current_ensembl_release();
    if (!$release_info){
      $release_info = $rdba->fetch_current_ensembl_genomes_release();
      $release = $release_info->{ensembl_genomes_version};
    }
    else{
      $release = $release_info->{ensembl_version};
    }
    $gdba->data_release($release_info);
  }
  return ($rdba,$gdba,$release,$release_info);
}

=head2 parse_ini_file
  Description: Subroutine parsing an ini file. I am reusing code from https://github.com/Ensembl/ensembl-metadata/blob/master/modules/Bio/EnsEMBL/MetaData/AnnotationAnalyzer.pm
  Arg        : ini file GitHub URL
  Returntype : Hash ref (keys are method parameter, values are associated parameter value)
  Exceptions : none
  Caller     : general
  Status     : Stable
=cut

sub parse_ini_file {
  my ($ini_file)= @_ ;
  my $ua = LWP::UserAgent->new();
  my $req = HTTP::Request->new( GET => $ini_file );
  # Pass request to the user agent and get a response back
  my $res = $ua->request($req);
  my $ini;
  # Check the outcome of the response
  if ( $res->is_success ) {
    $ini = $res->content;
  }
  else {
    die( "Could not retrieve $ini_file: " . $res->status_line );
  }
  my @array = split(/\n/,"$ini");
  return \@array;
}
1;

