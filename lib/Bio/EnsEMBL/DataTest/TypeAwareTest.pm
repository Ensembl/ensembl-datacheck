=head1 LICENSE

Copyright [2016] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Bio::EnsEMBL::DataTest::TypeAwareTest;
use Moose;
use Carp;
use Data::Dumper;

extends 'Bio::EnsEMBL::DataTest::BaseTest';

has 'per_species' => ( is => 'ro', default => 1, isa => 'Bool', required => 0 );
has 'db_types' => ( is => 'ro', isa => 'ArrayRef[Str]' );

after 'run' => sub {
  my ( $self, $dba ) = @_;
  $self->log()->debug("Disconnecting from ".$dba->dbc()->dbname());
  $dba->dbc()->disconnect_if_idle();
  return;
};

override 'will_test' => sub {
  
  my ( $self, $dba ) = @_;
  my $result = super();
  if($result->{run} !=1 ){
    return $result;
  }
  return $self->check_type($dba);
};

sub has_type {
  my ($self,$t) = @_;
  return grep {$t eq $_} @{$self->{db_types}};
}

sub check_type {
  my ($self,$dba) = @_;
    if ( !defined $self->{db_types}  || scalar (@{$self->{db_types}})==0 ) {
    return { run => 1, reason => "no type specified" };
  }
  my $dbname = $dba->dbc()->dbname();
  # core
  if($dbname =~ '_core_') {
    if(!$self->has_type('core')) {
      return {run=>0, reason=>'Test will not work with a core database'};      
    } elsif(!$dba->isa('Bio::EnsEMBL::DBSQL::DBAdaptor')) {
      return {run=>0, reason=>'Test requires a Bio::EnsEMBL::DBSQL::DBAdaptor'};      
    }
  } elsif($dbname =~ /_otherfeatures_/) {
    if($self->has_type('otherfeatures')) {
      return {run=>0, reason=>'Test will not work with an otherfeatures database'};      
    } elsif(!$dba->isa('Bio::EnsEMBL::DBSQL::DBAdaptor')) {
      return {run=>0, reason=>'Test requires a Bio::EnsEMBL::DBSQL::DBAdaptor'};      
    }
  } elsif($dbname =~ /_variation_/) {
    if(!$self->has_type('variation')) {
      return {run=>0, reason=>'Test will not work with a variation database'};      
    } elsif(!$dba->isa('Bio::EnsEMBL::Variation::DBSQL::DBAdaptor')) {
      return {run=>0, reason=>'Test requires a Bio::EnsEMBL::Variation::DBSQL::DBAdaptor'};      
    }    
  } elsif($dbname =~ /_compara_/) {
    if(!$self->has_type('compara')) {
      return {run=>0, reason=>'Test will not work with a compara database'};      
    } elsif(!$dba->isa('Bio::EnsEMBL::Compara::DBSQL::DBAdaptor')) {
      return {run=>0, reason=>'Test requires a Bio::EnsEMBL::Compara::DBSQL::DBAdaptor'};      
    }    
  } elsif($dbname =~ /_funcgen_/) {
    if(!$self->has_type('funcgen')) {
      return {run=>0, reason=>'Test will not work with a funcgen database'};      
    } elsif(!$dba->isa('Bio::EnsEMBL::Funcgen::DBSQL::DBAdaptor')) {
      return {run=>0, reason=>'Test requires a Bio::EnsEMBL::Funcgen::DBSQL::DBAdaptor'};      
    }    
  } else {
    croak "Cannot check correct type for database $dbname";
  }
  return {run=>1};
  
}

1;
