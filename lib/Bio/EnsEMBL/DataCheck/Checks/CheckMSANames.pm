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

package Bio::EnsEMBL::DataCheck::Checks::CheckMSANames;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckMSANames',
  DESCRIPTION    => 'Ensure that every MSA method has a name in species_set_header',
  GROUPS         => ['compara', 'compara_master', 'compara_genome_alignments'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['method_link', 'method_link_species_set', 'species_set_header']
};

sub skip_tests {
    my ($self) = @_;
    my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
    my @methods = qw( EPO EPO_EXTENDED PECAN );
    my $db_name = $self->dba->dbc->dbname;
    
    my @mlsses;
    foreach my $method ( @methods ) {
      my $mlss = $mlss_adap->fetch_all_by_method_link_type($method);
      push @mlsses, @$mlss;
    }

    if ( scalar(@mlsses) == 0 ) {
      return( 1, "There are no multiple alignments in $db_name" );
    }

}

sub tests {
  my ($self) = @_;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my @methods = qw( EPO EPO_EXTENDED PECAN );
  my $db_name = $self->dba->dbc->dbname;
  my $dbc = $self->dba->dbc;
  my @mlsses;

  foreach my $method ( @methods ) {
    my $mlss = $mlss_adap->fetch_all_by_method_link_type($method);
    push @mlsses, @$mlss;
  }
  
  foreach my $mlss ( @mlsses ) {
    my $mlss_id = $mlss->dbID;
    my $mlss_name = $mlss->name;
    my $ss_name = $mlss->species_set->name;
    my $ss_id = $mlss->species_set->dbID;
    isnt( $ss_name, '', "species_set_id $ss_id for method_link_species_set_id $mlss_id ($mlss_name) has a name: '$ss_name'" );
  }
}

1;
