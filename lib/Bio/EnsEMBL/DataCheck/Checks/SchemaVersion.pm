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

package Bio::EnsEMBL::DataCheck::Checks::SchemaVersion;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'SchemaVersion',
  DESCRIPTION => 'make sure the schema version is the same as the DB name',
  GROUPS      => ['EGCoreHandover'],
  DB_TYPES    => ['core']
};

sub tests {
  my ($self) = @_;

  my $db_name = $self->dba->dbc->dbname;

  ##Get the inferred version from the name
  my $version_from_name;
  if ($db_name =~ /(core|variation|otherfeatures|funcgen)_\d+_(\d+)_\d+/){
    $version_from_name = $2;
  }

  ##Check that the schema version is as expected from db name
  my $sql = "select count(*) from meta where meta_key='schema_version' and meta_value='$version_from_name'";
  my $desc = "checking schema version is the same as version in DB name";
  is_rows_nonzero($self->dba, $sql, $desc);

}

1;

