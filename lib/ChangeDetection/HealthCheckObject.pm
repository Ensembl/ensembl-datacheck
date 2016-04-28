package ChangeDetection::HealthCheckObject;

use Moose;
use File::Spec;

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

sub check_if_table_applicable{
    my ($self, $table) = @_;
    
    my @tables = @{ $self->tables };
    
    if( grep($table, @tables) ){
        $self->applicable(1);
    }
}

sub check_if_type_applicable{
    my ($self, $table) = @_;
}

sub say_hi{
    my ($self) = @_;
   
    my $name = $self->name;
    
    print "$name says hi!\n";
}

sub run_healthcheck{
    my ($self) = @_;
 
    my $parent_dir = File::Spec->updir;
    
    my $file;
    
    my $hc_type = $self->hc_type;
    my $name = $self->name;
    
    if($hc_type == 1){
        $file = File::Spec->catfile(('1-integrity'), "$name.pl");
    }
    elsif($hc_type == 2){
        $file = File::Spec->catfile(('2-integrity'), "$name.pl");
    }
    elsif($hc_type == 3){
        $file = File::Spec->catfile(('3-sanity'), "$name.pl");
    }
    elsif($hc_type == 4){
        $file = File::Spec->catfile(('4-sanity'), "$name.pl");
    }
    elsif($hc_type == 5){
        $file = File::Spec->catfile(('5-comparison'), "$name.pl");
    }
    else{
        print "Unknown healthcheck type \n"
        # ~~~This could do with better handling ~~~
    }
    
    if(defined $file){
    #also put -e ?
        my $cmd = "perl $file --config_file 'config'";
        
        if($name eq 'CoreForeignKeys'){
            $cmd .= " --filter_tables";
        }
        system($cmd);
    }
}
1;