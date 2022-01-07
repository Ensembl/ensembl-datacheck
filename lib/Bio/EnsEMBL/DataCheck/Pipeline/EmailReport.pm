=head1 LICENSE
Copyright [2018-2022] EMBL-European Bioinformatics Institute

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
Bio::EnsEMBL::DataCheck::Pipeline::EmailReport

=head1 DESCRIPTION
Send an email with the overall result of the datachecks,
and links to output files, if they were created.

=cut

package Bio::EnsEMBL::DataCheck::Pipeline::EmailReport;

use strict;
use warnings;
use feature 'say';

use base ('Bio::EnsEMBL::Hive::RunnableDB::NotifyByEmail');

sub fetch_input {
  my $self = shift;

  my $dbname       = $self->param('dbname');
  my $passed       = $self->param('datachecks_passed');
  my $failed       = $self->param('datachecks_failed');
  my $skipped      = $self->param('datachecks_skipped');
  my $history_file = $self->param('history_file');
  my $output_file  = $self->param('output_file');

  my $subject;
  if ($failed) {
    $subject = "FAIL: Datachecks for $dbname";
  } else {
    $subject = "PASS: Datachecks for $dbname";
  }
  $self->param('subject', $subject);

  my $text =
    "All datachecks for $dbname have completed: $passed passed ".
    "(of which $skipped were skipped) and $failed failed.\n";

  if (defined $history_file) {
    $text .= "The datacheck results were stored in a history file: $history_file.\n";
  } else {
    $text .= "The datacheck results were not stored in a history file.\n";
  }

  if (defined $output_file) {
    $text .= "The full output of the datachecks were stored in a file: $output_file.\n";
  } else {
    $text .= "The full output of the datachecks were not stored in a file.\n";
  }

  $self->param('text', $text);
}

1;
