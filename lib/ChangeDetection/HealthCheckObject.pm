=head1 NAME

  ChangeDetection::HealthCheckObject  - object module
  
=head1 SYNOPSIS

  use ChangeDetection::HealthCheckObject;
  
  my $healthcheck = ChangeDetection::HealthcheckObject::new->(
    name => 'AssemblyMapping',
    hc_type => 2,
    tables => ['coord_system', 'meta'],
    db_type => 'core',
  );

=head1 DESCRIPTION

  Creates healthcheck objects that can be used by a framework for running them. Every healthcheck object has
  5 properties: a name (the name of the perl script without the '.pl' extension), the type of healthcheck (the
  number of the category, i.e. for 2-integrity that would be 2), an array reference containing all the tables
  the healthcheck uses, the database type the healthcheck applies to (i.e. 'core', or 'generic' if it applies to all
  generic databases), and an flagging property called 'applicable' (default to 0), which can be used by the
  framework to mark the necessary healthchecks.
  
=cut

package ChangeDetection::HealthCheckObject;

use Moose;
use File::Spec;

use Bio::EnsEMBL::Utils::Exception qw(throw warning);

use namespace::autoclean;

has 'name' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has 'hc_type' => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

has 'tables' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    required => 1,
);

has 'db_type' => (
    is => 'ro',
    isa => 'Str',
    default => 'generic',
);

has 'applicable' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

=head2 say_hi

  small function to see which healthcheck you have :)
  
=cut

sub say_hi{
    my ($self) = @_;
   
    my $name = $self->name;
    
    print "$name says hi!\n";
}

=head2 run_healthcheck

  ARG[path]     : String - (relative) path to the main healthcheck directory from which the healthceck folders
                            can be accessed.
  ARG[command]  : String - additional (command line) input arguments for when the healthcheck is called, i.e.
                            specifiying the path to the config file with --config '[path]'
                     
  Runs the healthcheck object with which it is called. Take care to specifiy the correct path, which is relative
  to the current directory from which this function is called. Also remember to specifiy the path to the config
  file in this manner.
  
=cut

sub run_healthcheck{
    my ($self, %arg_for) = @_;
    
    my $path = $arg_for{path};
    my $command = $arg_for{command};
 
    my $parent_dir = File::Spec->updir;
    
    my $file;
    
    my $hc_type = $self->hc_type;
    my $name = $self->name;
    
    if($hc_type == 1){
        $file = File::Spec->catfile(($path,'1-integrity'), "$name.pl");
    }
    elsif($hc_type == 2){
        $file = File::Spec->catfile(($path, '2-integrity'), "$name.pl");
    }
    elsif($hc_type == 3){
        $file = File::Spec->catfile(($path, '3-sanity'), "$name.pl");
    }
    elsif($hc_type == 4){
        $file = File::Spec->catfile(($path, '4-sanity'), "$name.pl");
    }
    elsif($hc_type == 5){
        $file = File::Spec->catfile(($path, '5-comparison'), "$name.pl");
    }
    else{
        warning("Unknown healthcheck type - cannot run healthcheck $name");
    }
    
    if(defined $file){
        if(-f $file){
            my $cmd = "perl $file $command";
            
            system($cmd);
        }
        else{
            warning("Cannot find the healthcheck script at $file!");
        }
    }
}
1;