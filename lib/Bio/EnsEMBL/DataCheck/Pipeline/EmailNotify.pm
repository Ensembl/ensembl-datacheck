=head1 LICENSE
Copyright [2018-2020] EMBL-European Bioinformatics Institute

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
Bio::EnsEMBL::DataCheck::Pipeline::EmailNotify

=head1 DESCRIPTION
Send an email with the failed datacheck name, database name and the full output

=cut

package Bio::EnsEMBL::DataCheck::Pipeline::EmailNotify;

use strict;
use warnings;
use feature 'say';

use base ('Bio::EnsEMBL::Hive::RunnableDB::NotifyByEmail');

sub fetch_input {
  my $self = shift;
  my $datacheck_name   = $self->param('datacheck_name');
  my $datacheck_output = $self->param('datacheck_output');
  my $datacheck_params = $self->param('datacheck_params');
  my $pipeline_name    = $self->param('pipeline_name');

  my $dbname = $datacheck_params->{dba_params}->{-DBNAME};

  my $subject = "FAILED: Datacheck $datacheck_name for $dbname";
  $self->param('subject', $subject);
  my $text =
    "Datacheck $datacheck_name failed for $dbname in $pipeline_name pipeline.".
    "See full output below: \n $datacheck_output";
  $self->param('text', $text);
}
1;
