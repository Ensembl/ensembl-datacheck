
=head1 NAME

  DataFiles - A sanity test (type 4 in the healthcheck system).

=head1 SYNPOSIS

  $ perl DataFiles.pl 'homo sapiens'

=head1 DESCRIPTION

  ARG[Species Name]    : String - Name of the species to test on.
  Database type        : RNASEQ (hardcoded).

File names inserted in the data_file table should not have file extensions or spaces
in their names. The data files API will automatically deal with file extensions.

Perl adaptation of the DataFiles.java test.
See: https://github.com/Ensembl/ensj-healthcheck/blob/release/83/src/org/ensembl/healthcheck/testcase/generic/DataFiles.java

=cut

#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Getopt::Long;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

use Logger;

my $registry = 'Bio::EnsEMBL::Registry';

my $parent_dir = File::Spec->updir;
my $file = $parent_dir . "/config";

my $species;

my $config = do $file;
if(!$config){
    warn "couldn't parse $file: $@" if $@;
    warn "couldn't do $file: $!"    unless defined $config;
    warn "couldn't run $file"       unless $config; 
}
else {
    $registry->load_registry_from_db(
        -host => $config->{'db_registry'}{'host'},
        -user => $config->{'db_registry'}{'user'},
        -port => $config->{'db_registry'}{'port'},
    );
    #if there is command line input use that, else take the config file.
    GetOptions('species:s' => \$species);
    if(!defined $species){
        $species = $config->{'species'};
    }
} 

#this could do with a warning/catch when the dbadaptor doesn't exist for a species
my $dba = $registry->get_DBAdaptor($species, 'rnaseq');

my $log = Logger->new({
    healthcheck => 'DataFiles',
    type => 'rnaseq',
    species => $species,    
});

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc()
);

my $result = 1;

#get all the names
my $sql = "SELECT name FROM data_file";

my $names_ref = $helper->execute(
   -SQL => $sql,
);

#An arrayref is returned so we need to iterate over the entries of all the arrays
foreach my $row (@$names_ref){
    foreach my $name (@$row){
        $result &= find_extensions($name);
        $result &= find_spaces($name);
   }
}

$log->result($result);


sub find_extensions{
    my ($name) = @_;

    #look if the name ends in .A-Za-z format
    if($name =~ /\.([A-Za-z]+)$/){
        $log->message("PROBLEM: $name might have a file extension as end.");
        return 0;
    }
    else{
        return 1;
    }
}

sub find_spaces{
    my ($name) = @_;
    
    #look for any spaces in the file name.
    if(index($name, " ") != -1){
        $log->message("PROBLEM: There's a space in filename " . $name);;
        return 0;
    }
    else{
        return 1;
    }
}

