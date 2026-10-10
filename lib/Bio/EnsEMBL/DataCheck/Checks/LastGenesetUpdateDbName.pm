=head1 LICENSE

Copyright [2018-2026] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::LastGenesetUpdateDbName;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'LastGenesetUpdateDbName',
  DESCRIPTION    => 'genebuild.last_geneset_update matches the database name suffix',
  GROUPS         => ['core', 'meta'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['meta']
};

sub tests {
  my ($self) = @_;

  my $meta_key = 'genebuild.last_geneset_update';
  my $mca = $self->dba->get_adaptor("MetaContainer");
  my $values = $mca->list_value_by_key($meta_key);

  my $desc_1 = "Exactly one value exists for meta_key $meta_key";
  is(scalar @$values, 1, $desc_1);
  return unless scalar @$values == 1;

  # Accept YYYY_MM, YYYY-MM or YYYYMM, e.g. 2026_04 => 202604
  my $update = $$values[0];
  (my $normalised = $update) =~ s/\D//g;

  my $desc_2 = "$meta_key '$update' is in YYYY_MM format";
  ok($normalised =~ /^\d{4}(0[1-9]|1[0-2])$/, $desc_2);

  # e.g. homo_sapiens_core_114_202604 => 202604
  my $dbname = $self->dbname;
  my ($suffix) = $dbname =~ /_core_\d+_(\d+)$/;

  my $desc_3 = "$meta_key '$update' ($normalised) matches suffix of database name $dbname";
  ok(defined $suffix && $suffix eq $normalised, $desc_3);
}

sub dbname {
  my ($self) = @_;

  return $self->dba->dbc->dbname;
}

1;
