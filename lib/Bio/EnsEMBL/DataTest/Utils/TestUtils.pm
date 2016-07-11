=head1 LICENSE

Copyright [2016] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Bio::EnsEMBL::DataTest::Utils::TestUtils;
use warnings;
use strict;
use Data::Dumper;
use Carp;

BEGIN {
  require Exporter;
  our $VERSION   = 1.00;
  our @ISA       = qw(Exporter);
  our @EXPORT_OK = qw(freeze_builder restore_builder run_test);
}

sub run_test {
  my ($sub) = @_;
  my $b = freeze_builder( Test::More->builder() );
  Test::More->builder()->reset();
  my $res = &$sub;
  restore_builder( Test::More->builder(), $b );
  return $res;
}

sub freeze_builder {
  my ($builder) = @_;
  my $copy = {};
  for my $k ( keys %$builder ) {
    $copy->{$k} = copy( $builder->{$k} );
  }
  return $copy;
}

sub copy {
  my ($v) = @_;
  my $ov = $v;
  if ( ref($v) eq 'ARRAY' ) {
    $ov = [];
    for my $vv (@$v) {
      push @$ov, copy($vv);
    }
  }
  elsif ( ref($v) eq 'HASHREF' ) {
    $ov = {};
    while ( my ( $k, $vv ) = each %$v ) {
      $ov->{$k} = copy($vv);
    }
  }
  return $ov;
}

sub restore_builder {
  my ( $builder, $settings ) = @_;
  while ( my ( $k, $v ) = each %$settings ) {
    $builder->{$k} = $v;
  }
  return;
}

1;
