=head1 LICENSE

Copyright [2018-2020] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::ForeignKeysControlledTablesCore;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/foreign_keys/;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME        => 'ForeignKeysControlledTablesCore',
  DESCRIPTION => 'Foreign key relationships for tables imported from the production database',
  GROUPS      => ['controlled_tables'],
  DB_TYPES    => ['cdna', 'core', 'otherfeatures', 'rnaseq'],
  TABLES      => ['attrib_type', 'biotype', 'external_db', 'misc_set', 'unmapped_reason'],
  PER_DB      => 1
};

sub tests {
  my ($self) = @_;

  my ($foreign_keys, $failed_to_parse) = foreign_keys($self->dba->group);

  my %tables = map { $_ => 1 } @{$self->tables};
  foreach my $relationship (@$foreign_keys) {
    my ($table1, $col1, $table2, $col2) = @$relationship;
    if (exists $tables{$table2}) {
      fk($self->dba, @$relationship);
    }
  }

  my $desc_parsed = "Parsed all foreign key relationships from file";
  is(scalar(@$failed_to_parse), 0, $desc_parsed) ||
    diag explain @$failed_to_parse;
}

1;
