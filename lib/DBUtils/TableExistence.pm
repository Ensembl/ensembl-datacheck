package DBUtils::TableExistence;

use strict;
use warnings;

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
    
