=head1 NAME

DBUtils::MultiSpecies

=head1 SYNOPSIS

  my $multi_species_boolean = DBUtils::MultiSpecies::is_multi_species($dba);

  my $multiple_species_ids_ref = DBUtils::MultiSpecies::get_multi_species_ids($helper);

=head1 DESCRIPTION

A module providing functions for dealing with multiple species databases.

=cut

package DBUtils::MultiSpecies;

use strict;
use warnings;

=head2 is_multi_species

  ARG[Database Adaptor]     : DBAdaptor

  Returntype                : Boolean (0/1)

Checks if the database associated with the given database adaptor is multispecies. Multispecies
databases have the string "_collection_"  somewhere in their database name.

=cut

sub is_multi_species{
    my ($dba) = @_;

    my $dbname = ($dba->dbc())->dbname();

    if(index($dbname, "_collection_") != -1){
        return 1;
    }
    else{
        return 0;
    }

}

=head2 get_multi_species_ids

   ARG[helper]       : Bio::EnsEMBL::Utils::SqlHelper instance

   Returntype        : Arrayreference

Returns an arrayref of the distinct species_id's in a multispecies database. Works for one-species
databases as well but would just return one id.

=cut

sub get_multi_species_ids{
    my ($helper) = @_;

    my $sql = "SELECT DISTINCT(species_id) FROM meta WHERE species_id IS NOT NULL";
    
    my $result = $helper->execute(
        -SQL => $sql,
    );
   
    return $result;
}

1;
    
