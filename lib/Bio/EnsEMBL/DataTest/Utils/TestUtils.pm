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
