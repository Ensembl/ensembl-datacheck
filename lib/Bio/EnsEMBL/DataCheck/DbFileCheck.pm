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
Bio::EnsEMBL::DataCheck::DbFileCheck

=head1 DESCRIPTION
Test that accepts two database adaptors for comparison

=cut

package Bio::EnsEMBL::DataCheck::DbFileCheck;

use strict;
use warnings;
use feature 'say';

use Moose;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

=head1 METHODS

=head2 data_file
  Description: File containing data used for comparison.
=cut
has 'data_file' => (
  is  => 'rw',
  isa => 'Str | Undef',
);

before 'tests' => sub {
  my $self = shift;

  unless (defined $self->data_file && -e $self->data_file) {
    die "Path to data file must be set as 'data_file' attribute";
  }
};

1;
