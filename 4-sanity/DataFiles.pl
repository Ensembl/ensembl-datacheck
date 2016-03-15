
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

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

#Follows the old DataFiles check

#finding species like this is temporary (probably).
my $species = $ARGV[0];

my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
	-host => 'ensembldb.ensembl.org',
	-user => 'anonymous',
	-port => 3306,
);

my $dba = $registry->get_DBAdaptor($species, 'rnaseq');

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

if($result == 0){
   #in lieu of a better return mechanism atm.
   print "FAILURE: Some filenames were not in the required format. See report. \n";
}
else{
   print "SUCCESS: All filenames were in the right format. \n";
}


sub find_extensions{
    my ($name) = @_;

    #look if the name ends in .A-Za-z format
    if($name =~ /\.([A-Za-z]+)$/){
        print $name . " might have a file extension as end. \n";
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
        print "There's a space in filename " . $name . "\n";
        return 0;
    }
    else{
        return 1;
    }
}

