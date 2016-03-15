package DB::Registry;

#all the tools needed to connect to the Ensembl database and perform queries in one place

use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

#create a registry. ATM this isn't really quicker than the normal. Debatable whether necessary.
sub get_registry {
  my ($host, $user, $port) = @_;

  Bio::EnsEMBL::Registry->load_registry_from_db(
    -host => $host,
    -user => $user,
    -port => $port,
  );
}

#Connects to the database and creates a helper
#INPUT: species and database
#OUTPUT: a helper instance of Bio::EnsEMBL::Utils::SqlHelper
sub get_helper {
  my ($species, $database) = @_;

  my $dba = Bio::EnsEMBL::Registry->get_DBAdaptor($species, $database);

  my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
    -DB_CONNECTION => $dba->dbc(),
  );

  return $helper;	
}

1;
