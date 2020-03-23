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

package Bio::EnsEMBL::DataCheck::Checks::HGNCNumeric;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;;
extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'HGNCNumeric',
  DESCRIPTION    => 'Check that no HGNC xrefs have dbprimary_acc=display_label',
  GROUPS         => ['core', 'xref'],
  DATACHECK_TYPE => 'critical',
  TABLES         => ['xref'],
  PER_DB         => 1
};

sub tests {

  my ($self) = @_;
  my $threshold = 0.01;
  my $desc_1 = "All HGNC xrefs (or more than  (". $threshold * 100 .")%) have different dbprimary_acc and display_label";
  my $all_sql = qq/
       SELECT COUNT(*) FROM external_db e, xref x, object_xref ox, gene g 
       WHERE e.external_db_id=x.external_db_id 
       AND x.xref_id=ox.xref_id 
       AND ox.ensembl_object_type='Gene' 
       AND ox.ensembl_id=g.gene_id 
       AND e.db_name LIKE 'HGNC%'
  /;
  my $numeric_sql = $all_sql . " AND x.dbprimary_acc=x.display_label";
  my $all_rows = sql_count($self->dba, $all_sql);
  if ( $all_rows == 0 ){

      pass( $desc_1);
 
   }else{
      my $rows_numeric = sql_count($self->dba, $numeric_sql);
      my $fraction = $rows_numeric / $all_rows;
      if ($fraction > $threshold) {

        pass( $rows_numeric .  " (" . $fraction * 100 . "%) HGNC xrefs with dbprimary_acc=display_label;" .
                      " this will cause genes to have numeric display names, or break hyperlinks");

      } else {

        fail( "All HGNC xrefs (or more than ". $threshold * 100 . "%) have different dbprimary_acc and display_label");

      }
  
   }
}

1;

