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
Bio::EnsEMBL::DataCheck::Pipeline::DataCheckMailSummary

=head1 DESCRIPTION
Collective DC reports send it via email.

=cut

package Bio::EnsEMBL::DataCheck::Pipeline::DataCheckMailSummary;

use strict;
use warnings;
use feature 'say';

use JSON;
use Time::Piece;

use base ('Bio::EnsEMBL::Hive::RunnableDB::NotifyByEmail');

sub run {
  my $self = shift;

  my $json_output_file = $self->param('json_output_file');
  my $email            = $self->param('email');
  if ( defined $email && -e $json_output_file && -s $json_output_file ) {
    $self->set_email_parameters();
    $self->SUPER::run();
  }
}

sub set_email_parameters {
  my $self = shift;
  
  my $subject = "FAILED: Adivisory Datacheck Report For Pipeline ". $self->param('pipeline_name');
  $self->param('subject', $subject);
  my $text = "All datachecks have completed.\n";
  my $output_dir = $self->param('output_dir');

  if (defined $output_dir) {
    $text .= "The full output of the datachecks were stored in: $output_dir\n";
  } else {
    $text .= "The full output of the datachecks were not stored.\n";
  }
  my $json_output_file = $self->param('json_output_file');
  if (defined $json_output_file) {
    $text .= "Failures were stored in JSON format: $json_output_file\n";
    if (-s $json_output_file < 2e6) {
      push @{$self->param('attachments')}, $json_output_file;
    } else {
      $text .= "(JSON file not attached because it exceeds 2MB limit)";
    }

  } else {
    $text .= "The results were not stored in JSON format.\n";
  }
  $self->param('text', $text);
}

1;
