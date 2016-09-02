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

=head1 NAME

Bio::EnsEMBL::DataTest::CompareDbTest

=head1 SYNOPSIS

my $test = Bio::EnsEMBL::DataTest::CompareDbTest->new(
  name => 'compare_previous_biotypes',
  db_types => ['core'],
  tables   => ['gene'],
  test     => sub {
    my ( $dba, $dba2 ) = @_;
    my $sql = q/select biotype,count(*) from gene 
    join seq_region using (seq_region_id) 
    join coord_system using (coord_system_id) where species_id=/ .
      $dba->species_id() . ' group by biotype';
    is_same_counts( $dba, $dba2, $sql, 0.75, "Comparing biotype counts" );
    return;
  } );

my $res = $test->run($dba1,$dba2);

=head1 DESCRIPTION

Test that accepts two database adaptors for comparison

=head1 METHODS

=cut

package Bio::EnsEMBL::DataTest::CompareDbTest;
use Moose;

extends 'Bio::EnsEMBL::DataTest::TableAwareTest';

has 'tables' => ( is => 'ro', isa => 'ArrayRef[Str]' );

around 'will_test' => sub {

  my ( $orig, $self, $dba, $table_info, $dba2, $table_info2 ) = @_;

  # test the first database
  my $result = $self->$orig($dba, $table_info);

  if ( $result->{run} != 1 ) {
    return $result;
  }
  
  # test the second database
  return $self->check_tables( $dba2, $table_info2 );
};

1;
