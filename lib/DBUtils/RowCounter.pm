
=head1 NAME

DBUtils::RowCounter

=head1 SYNOPSIS

use DBUtils::RowCounter;

my $number_of_rows = DBUtils::RowCounter::get_row_count({
    helper => $helper,
    sql => "SELECT program FROM analysis",
});

=head1 DESCRIPTION

A module with functions dealing with the counting the number
of rows returned by an SQL-query, to be used for Ensembl healthchecks
Uses the Ensembl Perl APIto make the queries.

=cut

package DBUtils::RowCounter;

use strict;
use warnings;

=head2 get_row_count

  ARG[helper]    : Bio::EnsEMBL::Utils::SqlHelper instance
  ARG[sql]       : String - The SQL query

  Returntype     : Scalar

Takes an sql helper and an SQL string and determines if the SQL lends
itself for a fast count (if the query contains 'SELECT COUNT'), and calls
the approriate count function. Returns the result of _get_count_fast or
_get_count_slow.

=cut

sub get_row_count {
    my ($arg_for) = @_;

    my $helper = $arg_for->{helper};
    my $sql = $arg_for->{sql};

     
    if(index(uc($sql), "SELECT COUNT") != -1 && index(uc($sql), "GROUP BY") == -1){
        #If the query contains a SELECT COUNT and no GROUP BY clause,
        #the no. of rows will be the first element returned by the query.
        return _get_count_fast($helper, $sql);
    }
    else{
        return _get_count_slow($helper, $sql);
    }
}

=head2 _get_count_fast

  ARG[helper]    : Bio::EnsEMBL::Utils::SqlHelper instance
  ARG[sql]       : String - The SQL query

  Returntype     : Scalar

=cut

sub _get_count_fast{
    my ($helper, $sql) = @_;
    
    my $count = $helper->execute(
        -SQL => $sql,
    );
    #the SELECT COUNT(*) value will be the first element in the arrayref.
    return $count->[0][0];
}

=head2 _get_count_slow

  ARG[helper]    : Bio::EnsEMBL::Utils::SqlHelper instance
  ARG[sql]       : String - The SQL query

  Returntype     : Scalar

=cut

sub _get_count_slow{
    my ($helper, $sql) = @_;

    my $rows = $helper->execute(
        -SQL => $sql,
    );

    return scalar @{$rows};
}


1;
