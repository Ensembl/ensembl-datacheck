package DBUtils::TableExistence;

use strict;
use warnings;

=head2 does_table_exist

  ARG(helper)      : Bio::EnsEMBL::Utils::SqlHelper instance
  ARG(table)       : String - name of the table
  
  Returntype       : Boolean
  
Checks if there is a table with the specified name in the database
attached to the helper object.

=cut

sub does_table_exist{
    my ($helper, $table) = @_;

    my $tables = $helper->execute(
	-SQL => "SHOW TABLES LIKE '$table'",
    );

    if(scalar @{ $tables }){
	return 1;
    }
    else{
	return 0;
    }
}

1;
    
