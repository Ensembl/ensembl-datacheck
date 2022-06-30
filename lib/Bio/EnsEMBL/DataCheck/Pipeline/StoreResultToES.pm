=head1 LICENSE
Copyright [2018-2021] EMBL-European Bioinformatics Institute

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
Bio::EnsEMBL::DataCheck::Pipeline::StoreResultToES

=head1 DESCRIPTION
Reads datacheck results stored in json file and submit to the emabassy Elastic Search  
=cut

package Bio::EnsEMBL::DataCheck::Pipeline::StoreResultToES;

use strict;
use warnings;
use feature 'say';

use JSON;
use Path::Tiny;
use Search::Elasticsearch;
use Bio::EnsEMBL::Utils::Exception qw/throw/;

use base ('Bio::EnsEMBL::Hive::Process');


sub run {
  my $self = shift;

  my $es_host       = $self->param_required('es_host');
  my $es_port       = $self->param_required('es_port');
  my $es_index      = $self->param_required('es_index');
  my $es_log        = $self->param_required('es_log_file');
  my $job_id        = $self->param('submission_job_id'); 
  my $json_filename = $self->param('json_output_file');


  my $es_client   = Search::Elasticsearch->new(
    trace_to => ['File', $es_log],
    nodes => [
        $es_host.":".$es_port, 
    ],
    cxn_pool => 'Static',
  );


  my $json_text = do {
     open(my $json_fh, "<:encoding(UTF-8)", $json_filename) or die("Can't open \"$json_filename\": $!\n");
     local $/;
     <$json_fh>
  };

  my $json = JSON->new;
  my $data = $json->decode($json_text);
  eval {
    $e->index(
      index   => $es_index,
      type    => 'report',
      body    => {
         job_id  => $job_id,    
         file    => $json_filename,
         content => $data,
      }
    );
  }
  if($@){
    throw "$@";
  }

}


1;
