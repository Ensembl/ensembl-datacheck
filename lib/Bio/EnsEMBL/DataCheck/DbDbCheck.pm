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
Bio::EnsEMBL::DataCheck::CompareDbCheck

=head1 DESCRIPTION
Test that accepts two database adaptors for comparison

=cut

package Bio::EnsEMBL::DataCheck::CompareDbCheck;

use strict;
use warnings;
use feature 'say';

use Moose;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

=head1 METHODS

=head2 second_dba
  Description: DBAdaptor object for database used for comparison.
=cut
has 'second_dba' => (
  is  => 'rw',
  isa => 'DBAdaptor | Undef',
);

before 'run' => sub {
  my ($self) = @_;

  if (!defined $self->second_dba) {
    die "DBAdaptor must be set as 'second_dba' attribute";
  }
};

after 'run' => sub {
  my ($self) = @_;

  $self->second_dba->dbc && $self->second_dba->dbc->disconnect_if_idle();
};

1;
