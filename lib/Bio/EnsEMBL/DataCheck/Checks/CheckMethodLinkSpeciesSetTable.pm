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

package Bio::EnsEMBL::DataCheck::Checks::CheckMethodLinkSpeciesSetTable;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'CheckMethodLinkSpeciesSetTable',
  DESCRIPTION    => 'Check for broken entries in method_link_species_Set',
  GROUPS         => ['compara'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['genome_db', 'method_link_species_set', 'species_set', 'species_set_header']
};

sub tests {
  my ($self) = @_;
  my $dba = $self->dba;
  my $mlss_adap = $self->dba->get_MethodLinkSpeciesSetAdaptor;
  my $mlss = $mlss_adap->fetch_all;
  
  foreach my $mlss ( @$mlss ) {
    my $mlss_name = $mlss->name;
    my $mlss_id = $mlss->dbID;
    my $species_set = $mlss->species_set;
    my $species_set_name = $species_set->name;
    my $species_set_id = $species_set->dbID;
    my $gdbs = $species_set->genome_dbs;
    my $gdb_count = scalar( @$gdbs );
    
    if ( $mlss_name =~ /(^[0-9]+) / && $1 != $gdb_count ) {
      fail("species_set $species_set_name and mlss $mlss_name both link to $gdb_count genomes");
    }
    if ( $mlss_name =~ /(^[0-9]+) / && $1 == $gdb_count ) {
      pass("species_set $species_set_name and mlss $mlss_name both link to $gdb_count genomes");
    }
    if ( $mlss_name =~ /^([a-zA-Z]+) /  ) {
      my $mlss_p1 = $1;
      if ( $mlss_name =~ /^protein|nc|species/ ) {
        fail("The current convention is in place for mlss $mlss_name and species_set $species_set_name");
      }
      else {
        pass("The current convention is in place for mlss $mlss_name and species_set $species_set_name");
      }
      if ( $species_set_name !~ /collection-$mlss_p1/ &&  $species_set_name !~ /$mlss_p1/ ) {
        fail("species_set $species_set_id for mlss $mlss_name starts with the species_set name $species_set_name"); 
      }
      else {
        pass("species_set $species_set_id for mlss $mlss_name starts with the species_set name $species_set_name");
      }
    }
  }

  
}

1;

