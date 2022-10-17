=head1 LICENSE
Copyright [2018-2022] EMBL-European Bioinformatics Institute
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

package Bio::EnsEMBL::DataCheck::Checks::AnnotationSource;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'AnnotationSource',
  DESCRIPTION    => 'If present, the annotation_source meta key must be from an approved list',
  GROUPS         => ['rapid_release'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['core'],
  TABLES         => ['meta']
};
sub tests{
  my ($self) = @_;
  
  my $mca = $self->dba->get_adaptor('MetaContainer');
  
 SKIP: {
     my $method = $mca->single_value_by_key('genebuild.method');
     if($method ne 'braker' && $method ne 'import' && $method ne 'external_annotation_import') {
         skip "Annotation source key not needed for Ensembl builds", 1;
     }

     my $desc = "'species.annotation_source' meta_key exists";
     my $annotation_source = lc($mca->single_value_by_key('species.annotation_source'));
     ok($annotation_source, $desc);

     my $sources = 'braker|genbank|refseq|community|flybase|wormbase|veupathdb|noninsdc';
     my $source_desc = "Source is allowed";

     skip 'species.annotation_source meta key does not exist', 1 unless defined $annotation_source;

     like($annotation_source, qr/^$sources$/, $source_desc);
  }


}
