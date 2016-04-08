package DBUtils::GetTableThing;

use strict;
use warnings;

sub get_all_table_names{
    my ($helper) = @_;

    my $sql = "SELECT TABLE_NAME from information_schema.TABLES "
                . "WHERE TABLE_SCHEMA = DATABASE() "
                . "AND TABLE_TYPE = 'BASE TABLE'";

    my $table_names = $helper->execute(
        -SQL => $sql
    );

    return $table_names;
}

sub get_table_info{
    my ($helper, $table) = @_;
    
    #do things
1;