=head1 LICENSE

Copyright [2018-2023] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::SequenceChecksum;

use warnings;
use strict;

use Moose;
use Test::More;
extends 'Bio::EnsEMBL::DataCheck::DbCheck';

=head2 exclude_lrgs
  Description: Exclude lrgs from the test. Excluded by default
=cut
has 'exclude_lrgs' => (
  is      => 'ro',
  isa     => 'Bool',
  default => 1
);

use constant {
  NAME           => 'SequenceChecksum',
  DESCRIPTION    => 'Check All checksum attribute are assigned to all genomic features',
  GROUPS         => ['sequence_checksum'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['seq_region_attrib', 'transcript_attrib', 'translation_attrib', 'seq_region', 'transcript', 'translation']
};

sub tests {
  my ($self) = @_;
  my $species_id = $self->dba->species_id;
  
  my %attrib_mapping = (
    toplevel     => ['sha512t24u_toplevel', 'md5_toplevel'],
    transcript   => ['sha512t24u_cdna', 'md5_cdna'],
    cds		 => ['sha512t24u_cds', 'md5_cds'],
    translation  => ['sha512t24u_pep', 'md5_pep'],
  );
  my %attrib_sql = (
    toplevel => qq/
      SELECT COUNT(*) FROM seq_region 
      INNER JOIN coord_system cs ON(cs.coord_system_id=seq_region.coord_system_id)
      INNER JOIN seq_region_attrib sra ON (seq_region.seq_region_id=sra.seq_region_id)
      INNER JOIN attrib_type at ON(at.attrib_type_id=sra.attrib_type_id)
      WHERE  cs.species_id=? AND at.code=?
    /,
    transcript => qq/
      SELECT COUNT(*) FROM transcript 
      INNER JOIN seq_region sr ON transcript.seq_region_id = sr.seq_region_id
      INNER JOIN coord_system cs ON sr.coord_system_id = cs.coord_system_id 
    /,
    cds => qq/
      SELECT COUNT(*) FROM transcript t
      INNER JOIN translation tr ON t.transcript_id = tr.transcript_id
      INNER JOIN seq_region sr ON t.seq_region_id = sr.seq_region_id
      INNER JOIN coord_system cs ON sr.coord_system_id = cs.coord_system_id 
      INNER JOIN transcript_attrib ta ON (t.transcript_id=ta.transcript_id)
      INNER JOIN attrib_type at ON (at.attrib_type_id=ta.attrib_type_id)
      WHERE  cs.species_id=? AND at.code=?
    /,
    translation => qq/
      SELECT COUNT(*) FROM translation 
      INNER JOIN transcript t ON translation.transcript_id = t.transcript_id 
      INNER JOIN seq_region sr ON t.seq_region_id = sr.seq_region_id
      INNER JOIN coord_system cs ON sr.coord_system_id = cs.coord_system_id 
    /
  );
  my $cds_feature_sql = qq/
      SELECT COUNT(*) FROM transcript t
      INNER JOIN translation tr ON t.transcript_id = tr.transcript_id
      INNER JOIN seq_region sr ON t.seq_region_id = sr.seq_region_id
      INNER JOIN coord_system cs ON sr.coord_system_id = cs.coord_system_id 
      WHERE  cs.species_id=?
  /;

  my $helper = $self->dba->dbc->sql_helper;
  my $feature_count;
  my $attrib_sql;
  foreach my $table (keys %attrib_mapping){
   $attrib_sql = $attrib_sql{$table};
   if( $table eq "toplevel"){
     my $params = [$species_id, 'toplevel'];
     if($self->exclude_lrgs()) {
      $attrib_sql .= ' AND cs.name <> ?';
      push(@{$params}, 'lrg');
     }
     $feature_count  = $helper->execute_single_result(
                       -SQL => $attrib_sql, 
	                     -PARAMS => $params
                     );
   } 
   elsif($table eq "cds") {
     my $params = [$species_id];
     if($self->exclude_lrgs()) {
      $cds_feature_sql .= ' AND cs.name <> ?';
      push(@{$params}, 'lrg');
      $attrib_sql .= ' AND cs.name <> ?';
     }
     $feature_count  = $helper->execute_single_result(
                       -SQL => $cds_feature_sql, 
		       -PARAMS => $params
                     );
   } else{
     my $params = [$species_id];
     $attrib_sql = $attrib_sql{$table}." WHERE  cs.species_id=?";
     if ($self->exclude_lrgs()) {
      $attrib_sql .= ' AND cs.name <> ?';
	    push(@{$params}, 'lrg');
     }
     $feature_count = $helper->execute_single_result(
                       -SQL => $attrib_sql,
                       -PARAMS => $params
                     );
     $attrib_sql = $attrib_sql{$table} . qq/  
                      INNER JOIN ${table}_attrib ta ON ${table}.${table}_id = ta.${table}_id
                      INNER JOIN attrib_type a ON ta.attrib_type_id = a.attrib_type_id
                      WHERE cs.species_id=? AND a.code=? /;		     
     $attrib_sql .= ' AND cs.name <> ?' if $self->exclude_lrgs();
   }

   foreach my $attrib_code (@{$attrib_mapping{$table}}){ 
     my $params = [$species_id, $attrib_code];
     push(@{$params}, 'lrg') if $self->exclude_lrgs();
     my  $attrib_count  = $helper->execute_single_result(
                           -SQL => $attrib_sql,
                           -PARAMS   => $params
                          );
     my $desc = "All $table assigned to attrib $attrib_code with checksum value";
     cmp_ok( $feature_count , "==", $attrib_count, $desc );			  
   }
  }
}

1;

