=head1 LICENSE
Copyright [2018] EMBL-European Bioinformatics Institute

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
Bio::EnsEMBL::DataCheck::Pipeline::EmailSummary

=head1 DESCRIPTION
Send an email with the overall summary for all datachecks.

=cut

package Bio::EnsEMBL::DataCheck::Pipeline::EmailSummary;

use strict;
use warnings;
use feature 'say';

use base ('Bio::EnsEMBL::Hive::RunnableDB::NotifyByEmail');

sub fetch_input {
  my $self = shift;

  my $submission_job_id = $self->param('submission_job_id');

  my $tag          = $self->param('tag');
  my $history_file = $self->param('history_file');
  my $output_dir   = $self->param('output_dir');

  my ($passed_total, $failed_total) = (0, 0);
  my $db_text = '';

  my $sql = q/
    SELECT dbname, passed, failed, skipped FROM datacheck_results
    WHERE submission_job_id = ?
    ORDER BY dbname
  /;
  my $sth = $self->dbc->prepare($sql);
  $sth->execute($submission_job_id);

  my $results = $sth->fetchall_arrayref();
  foreach my $result (@$results) {
    my ($dbname, $passed, $failed, $skipped) = @$result;

    $failed ? $failed_total++ : $passed_total++;

    $db_text .= "\tpassed: $passed";
    $db_text .= "\tfailed: $failed";
    $db_text .= "\tskipped: $skipped";
    $db_text .= "\t$dbname\n";
  }

  my $subject;
  if ($failed_total) {
    $subject = "FAIL: Datacheck Summary";
  } else {
    $subject = "PASS: Datacheck Summary";
  }

  my $passed_db = $passed_total == 1 ? 'database' : 'databases';
  my $failed_db = $failed_total == 1 ? 'database' : 'databases';

  my $text = "All datachecks have completed.\n".
    "$passed_total $passed_db passed all datachecks, ".
    "$failed_total $failed_db failed one or more datachecks.\n";

  if (defined $tag) {
    $subject .= " ($tag)";
    $text    .= "Submission tag: $tag\n";
  }
  $self->param('subject', $subject);

  $text .= "Details:\n$db_text";

  if (defined $history_file) {
    $text .= "The datacheck results were stored in a history file: $history_file.\n";
  } else {
    $text .= "The datacheck results were not stored in a history file.\n";
  }

  if (defined $output_dir) {
    $text .= "The full output of the datachecks were stored in: $output_dir.\n";
  } else {
    $text .= "The full output of the datachecks were not stored.\n";
  }

  $self->param('text', $text);
}

1;
