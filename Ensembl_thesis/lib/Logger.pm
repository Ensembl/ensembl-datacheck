=head1 NAME

  Logger
  
=head1 SYNOPSIS

  use Logger;
  
  my $log = Logger->new(
    healthcheck => 'LRG',
    species => $species,
    type => $database_type,
  );
  
  my $result = 1;
  
  $log->message("There is a problem");
  $result = 0;
  
  $log->result($result);
  
=head1 DESCRIPTION

  The Logger object provides a uniform informative output for the healthcheck system. The message method
  can be used for informative messages, whereas the result method is used to display the final success
  or failure of a healthcheck.

=cut

package Logger;

use Moose;
use namespace::autoclean;

use Term::ANSIColor  qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

has 'healthcheck' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has 'type' => (
    is => 'rw',
    isa => 'Str',
    default => 'undefined',
);

has 'species' => (
    is => 'rw',
    isa => 'Str',
    default => 'undefined',
);

=head2 message

  ARG(message)     : String - the message you want to print
  
Prints a message to STDOUT, prefixed with the healthcheck name, species,
and database type.  
  
=cut

sub message{
    my ($self, $message) = @_;
    
    my $healthcheck = uc($self->healthcheck);
    my $type = uc($self->type);
    my $species = uc($self->species);
    
    print BRIGHT_YELLOW "$healthcheck on $type database for species: $species \t $message \n";
}

=head2 result

  ARG(result)     : Boolean - indicating the success or failure of the healthcheck
  
Prints the final result of the healthcheck to STDOUT, with the healthcheck name, 
species, and database type.  
  
=cut

sub result{
    my ($self, $result) = @_;
    
    my $healthcheck = uc($self->healthcheck);
    my $type = uc($self->type);
    my $species = uc($self->species);
    
    if($result){
	print BRIGHT_GREEN "$result SUCCESS: $healthcheck on $type database for species $species passed succesfully \n";
    }
    else{
	print BRIGHT_RED "$result FAIL: $healthcheck on $type database for species $species failed: "
		. "please read the log to find out why. \n";
    }
    
}

1;

