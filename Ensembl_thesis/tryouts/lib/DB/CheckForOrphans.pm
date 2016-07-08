package DB::CheckForOrphans;

use strict;
use warnings;


use Term::ANSIColor qw(:constants);

$Term::ANSIColor::AUTORESET = 1;


sub count_orphans {
  #my ($helper, $table1, $col1, $table2, $col2) = @_;
  my (%arg_for) = @_;

  my $helper = $arg_for{helper};
  my $table1 = $arg_for{table1};
  my $col1   = $arg_for{col1};
  my $table2 = $arg_for{table2};
  my $col2   = $arg_for{col2};

  my $sql = " FROM " . $table1 . " LEFT JOIN " . $table2 .
    " ON " . $table1 . "." . $col1 . " = " . $table2 . "." . $col2 .
    " WHERE " . $table2 . "." . $col2 . " IS NULL";

  my $result_left = $helper->execute(
    -SQL => "SELECT COUNT(*)" . $sql,
  );

  my $orphan_count = $result_left->[0][0];

  if($orphan_count > 0){
    print BRIGHT_RED $orphan_count . " foreign key violations in " 
        . $table1 . "." . $col1 . " -> " . $table2 . "." . $col2 
        . "\n";
    return 0;
  }
  else{
    print BRIGHT_GREEN "No foreign key violations in "
        . $table1 . "." . $col1 . " -> " . $table2 . "." . $col2 
        . "\n";
    return 1;
  }
}

1;
