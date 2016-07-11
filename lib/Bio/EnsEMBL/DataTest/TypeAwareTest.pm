package Bio::EnsEMBL::DataTest::TypeAwareTest;
use Moose;
use Carp;
use Data::Dumper;

extends 'Bio::EnsEMBL::DataTest::BaseTest';

has 'db_types' => ( is => 'ro', isa => 'ArrayRef[Str]' );

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
  } else {
    croak "Cannot check correct type for database $dbname";
  }
  return {run=>1};
  
}

1;
