package DB::Reference;

#Deals with the array references returned by the Bio::EnsEMBL::Utils::SqlHelper execute functions.

use strict;
use warnings;

sub print_ref {

  my ($reference) = @_;

  foreach my $item (@$reference){

    if(ref($item) eq "ARRAY"){
      print "\n";
      print_ref($item);
    }

    else {
      if($item eq @$reference[0]){
        print "[";
      }
      if($item eq @$reference[-1]){
        print $item . "] \n";
      }
      else{
        print $item . "\t";
      }
    }

  }
}

sub make_array {
	
  my ($reference) = @_;

  #??
}

1;

