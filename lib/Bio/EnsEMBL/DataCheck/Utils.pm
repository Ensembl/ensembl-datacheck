=head1 LICENSE
Copyright [2018] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 NAME
Bio::EnsEMBL::DataCheck::Utils

=head1 DESCRIPTION
General purpose functions for datachecks.

=cut

package Bio::EnsEMBL::DataCheck::Utils;

use strict;
use warnings;
use feature 'say';

require Exporter;
our @ISA       = qw( Exporter );
our @EXPORT_OK = qw( repo_location sql_count );

use File::Spec::Functions qw/catdir splitdir/;

sub repo_location {
  my ($repo_name) = @_;

  foreach my $location (@INC) {
    my @dirs = splitdir($location);
    if (scalar(@dirs) >= 2) {
      if ($dirs[-2] eq $repo_name) {
        pop @dirs;
        return catdir(@dirs);
      }
    }
  }

  die "$repo_name was not found in \@INC:\n" . join("\n", @INC);
}

sub sql_count {
  my ($dbc, $sql, $params) = @_;

  $dbc = $dbc->dbc() if $dbc->can('dbc');

  if ( index( uc($sql), "SELECT COUNT" ) != -1 &&
       index( uc($sql), "GROUP BY" ) == -1 )
  {
    return $dbc->sql_helper()->execute_single_result( -SQL => $sql, -PARAMS => $params );
  } else {
    return scalar @{ $dbc->sql_helper()->execute( -SQL => $sql, -PARAMS => $params ) };
  }
}

1;
