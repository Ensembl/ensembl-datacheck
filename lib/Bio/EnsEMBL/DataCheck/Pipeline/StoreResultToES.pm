=head1 LICENSE
Copyright [2018-2023] EMBL-European Bioinformatics Institute

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

use Path::Tiny;
use Search::Elasticsearch;
use Bio::EnsEMBL::Utils::Exception qw/throw/;
use Bio::EnsEMBL::Registry;
use base ('Bio::EnsEMBL::Hive::Process');

sub run {
    my $self = shift;

    my $es_host = $self->param_required('es_host');
    my $es_port = $self->param('es_port');
    my $es_index = $self->param_required('es_index');
    my $es_log = $self->param_required('es_log_file');
    my $job_id = $self->param('submission_job_id');
    my $json_filename = $self->param('json_output_file');

    my $reg = 'Bio::EnsEMBL::Registry';
    if ($self->param_is_defined('registry_file')) {
        $reg->load_all($self->param('registry_file'));
    }

    my $input_details = $self->get_input_details();
    my $dbname = $self->param('dbname')->[0];
    my ($dba) = @{Bio::EnsEMBL::Registry->get_all_DBAdaptors_by_dbname($dbname)};
    if (!defined $dba) {
        throw "Database $dbname not found in registry.";
    }
    my $mca = $dba->get_adaptor('MetaContainer');
    my $division = $mca->single_value_by_key('species.division');

    my $es_url = $es_host;
    if (defined($es_port)) {
        $es_url .= ":" . $es_port
    }
    my $es_client = Search::Elasticsearch->new(
        trace_to => [ 'File', $es_log ],
        nodes    => [ 'http://localhost:9200/', ],
        cxn_pool => 'Static',
    );

    my $json_text = do {
        open(my $json_fh, "<:encoding(UTF-8)", $json_filename) or die("Can't open \"$json_filename\": $!\n");
        local $/;
        <$json_fh>
    };

    eval {
        $es_client->index(
            index => $es_index,
            type  => 'report',
            body  => {
                job_id        => $job_id,
                division      => $division,
                file          => $json_filename,
                content       => $json_text,
                input_details => $input_details,
            }
        );
    };
    if ($@) {
        throw "$@";
    }

}

sub get_input_details {

    my $self = shift;

    return {
        'config_file'      => $self->param('config_file'),
        'datacheck_groups' => $self->param('datacheck_groups'),
        'datacheck_names'  => $self->param('datacheck_names'),
        'datacheck_types'  => $self->param('datacheck_types'),
        'db_type'          => $self->param('db_type'),
        'dbname'           => $self->param('dbname'),
        'registry_file'    => $self->param('registry_file'),
        'server_uri'       => $self->param('server_uri'),
        'server_url'       => $self->param('server_url'),
        'tag'              => $self->param('tag'),
        'target_url'       => $self->param('target_url'),
        'timestamp'        => $self->param('timestamp'),
    }
}

1;
