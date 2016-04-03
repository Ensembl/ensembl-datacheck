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
    required => 1,
);

has 'species' => (
    is => 'rw',
    isa => 'Str',
);

sub message{
    my ($self, $message) = @_;
    
    my $healthcheck = uc($self->healthcheck);
    my $type = uc($self->type);
    my $species;
    if(defined $self->species){
        $species = uc($self->species);
    }
    else{
        $species = 'NOT DEFINED';
    }

    print YELLOW "$healthcheck on $type database for species: $species \t $message \n";
}

sub result{
    my($self, $result) = @_;
    
    my $healthcheck = uc($self->healthcheck);
    my $type = uc($self->type);
    my $species;
    if(defined $self->species){
        $species = uc($self->species);
    }
    else{
        $species = 'NOT DEFINED';
    }
    
    if($result == 1){
	print BRIGHT_GREEN "$result OK: $healthcheck on $type database for species $species passed succesfully \n";
    }
    else{
	print BRIGHT_RED "$result FAIL: $healthcheck on $type database for species $species failed: "
		. "please read the log to find out why. \n";
    }
    
  }

1;

