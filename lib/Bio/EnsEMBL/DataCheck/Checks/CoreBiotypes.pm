=head1 LICENSE

Copyright [2018] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the 'License');
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an 'AS IS' BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Bio::EnsEMBL::DataCheck::Checks::CoreBiotypes;

use warnings;
use strict;

use Moose;

use Test::Deep qw{ cmp_deeply };
use Test::More;
use Try::Tiny;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {  ## no critic 'ProhibitConstantPragma'
  NAME        => 'CoreBiotypes',
  DESCRIPTION => 'Checks if the biotype table in core databases has been populated with all the required biotypes',
  GROUPS      => ['core_handover'],
  DB_TYPES    => ['core'],
  TABLES      => ['biotype', 'gene', 'transcript']
};


# Note that this datacheck requires TWO databases to run: a core
# database to be checked and a Production database containing the
# master copy of the biotype table. The former is specified the
# standard way, the latter take advantage of - and possibly slightly
# abuses - the option -old_server_uri.
sub tests {
  my ($self) = @_;

  my $master_dba;
  try {
    $master_dba = $self->get_old_dba();
  } catch {
    # croak() doesn't do what it is supposed to do in test suites
    ## no critic 'RequireCarping'
    die "No connection to master DB! Check your -old_server_uri. Error message was: $_";
  };

  my $sql_helper = $self->dba()->dbc()->sql_helper();
  my $master_sql_helper = $master_dba->dbc()->sql_helper();

  my $sql_whole_biotype_table
    = 'SELECT * FROM biotype ORDER BY biotype_id';

  my $this_biotype_table = $sql_helper->execute(
    -SQL => $sql_whole_biotype_table
  );

  my $master_biotype_table = $master_sql_helper->execute(
    -SQL => $sql_whole_biotype_table
  );

  # Reminder: this *will* fail if results from both tables are not
  # ordered in the same way
  cmp_deeply( $this_biotype_table, $master_biotype_table,
              'biotype table in sync with master' );

  foreach my $object_type ( 'gene', 'transcript' ) {
    subtest "definitions of $object_type biotypes" => sub {

      my $biotypes_from_objects = $sql_helper->execute_simple(
        -SQL => "SELECT DISTINCT biotype FROM $object_type"
      );

      my $biotypes_defined_for_object_type = $sql_helper->execute_into_hash(
        -SQL      => "SELECT DISTINCT name FROM biotype WHERE object_type = '$object_type'",
        -CALLBACK => sub {
          return 1;
        }
      );

      while (my $biotype = shift @{ $biotypes_from_objects } ) {
        ok( exists $biotypes_defined_for_object_type->{$biotype},
            "$object_type biotype '$biotype' defined in biotype table" );
      }

    };
  }

  return;
}

1;

