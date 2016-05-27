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

sub message{
    my ($self, $message) = @_;
    
    my $healthcheck = uc($self->healthcheck);
    my $type = uc($self->type);
    my $species = uc($self->species);
    
    print BRIGHT_YELLOW "$healthcheck on $type database for species: $species \t $message \n";
}

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

