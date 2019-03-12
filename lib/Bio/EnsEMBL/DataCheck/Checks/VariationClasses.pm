=head1 LICENSE

Copyright [2018-2019] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::VariationClasses;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'VariationClasses',
  DESCRIPTION    => 'Variation number of classes is correct',
  GROUPS         => ['variation_import'],
  DB_TYPES       => ['variation'],
  TABLES         => ['variation', 'source']
};

sub tests {
  my ($self) = @_;
 
  my $species = $self->dba->species;

  if($species =~ /homo_sapiens/) {
    $self->checkClassAttrib('COSMIC', 'Number of variation classes is correct for source COSMIC');
    $self->checkClassAttrib('ClinVar', 'Number of variation classes is correct for source ClinVar');

    my $sql_hgmd = qq/
      SELECT COUNT(DISTINCT v.class_attrib_id)
      FROM variation v, source s
      WHERE s.name LIKE '%HGMD%'
      AND s.source_id = v.source_id
    /;
    cmp_rows($self->dba, $sql_hgmd, '>', '1', 'Number of variation classes is correct for source HGMD');
  } 

  $self->checkClassAttrib('dbSNP', 'Number of variation classes is correct for source dbSNP');

}

sub checkClassAttrib {
  my ($self, $source, $desc) = @_; 

  my $sql = qq/
      SELECT COUNT(DISTINCT v.class_attrib_id) 
      FROM variation v, source s
      WHERE s.name = '$source'
      AND s.source_id = v.source_id
  /; 
  cmp_rows($self->dba, $sql, '>', '1', $desc); 

}

1;

