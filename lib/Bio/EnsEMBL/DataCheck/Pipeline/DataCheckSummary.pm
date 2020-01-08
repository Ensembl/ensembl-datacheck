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
Bio::EnsEMBL::DataCheck::Pipeline::DataCheckSummary

=head1 DESCRIPTION
Store summary of datacheck results, and optionally send it via email.

=cut

package Bio::EnsEMBL::DataCheck::Pipeline::DataCheckSummary;

use strict;
use warnings;
use feature 'say';

use JSON;

use base ('Bio::EnsEMBL::Hive::RunnableDB::NotifyByEmail');

sub run {
  my $self = shift;

  my $submission_job_id = $self->param('submission_job_id');

  my $history_file = $self->param('history_file');
  my $output_dir   = $self->param('output_dir');
  my $tag          = $self->param('tag');
  my $email        = $self->param('email');
  my $timestamp    = $self->param('timestamp');

  my $sql = q/
    SELECT dbname, passed, failed, skipped FROM datacheck_results
    WHERE submission_job_id = ?
    ORDER BY dbname
  /;
  my $sth = $self->dbc->prepare($sql);
  $sth->execute($submission_job_id);

  my ($passed_total, $failed_total) = (0, 0);
  my %results;

  my $results = $sth->fetchall_arrayref();
  foreach my $result (@$results) {
    my ($dbname, $passed, $failed, $skipped) = @$result;

    $failed ? $failed_total++ : $passed_total++;

    $results{$dbname}{passed}  = $passed;
    $results{$dbname}{failed}  = $failed;
    $results{$dbname}{skipped} = $skipped;
  }

  my %output = (
    databases    => \%results,
    passed_total => $passed_total,
    failed_total => $failed_total,
    history_file => $history_file,
    output_dir   => $output_dir,
    tag          => $tag,
    timestamp    => $timestamp,
  );

  $self->param('output', \%output);

  if (defined $email) {
    $self->set_email_parameters();
    $self->SUPER::run();
  }
}

sub write_output {
  my $self = shift;

  my $output = {
    job_id => $self->param('submission_job_id'),
    output => JSON->new->pretty->encode($self->param('output')),
  };

  $self->dataflow_output_id($output, 1);
}

sub set_email_parameters {
  my $self = shift;
  
  my %output = %{ $self->param('output') };

  my $db_text;
  foreach my $dbname (sort keys %{$output{databases}}) {
    $db_text .= "\tpassed: "  . $output{databases}{$dbname}{passed};
    $db_text .= "\tfailed: "  . $output{databases}{$dbname}{failed};
    $db_text .= "\tskipped: " . $output{databases}{$dbname}{skipped};
    $db_text .= "\t$dbname\n";
  }

  my $subject;
  if ($output{failed_total}) {
    $subject = "FAIL: Datacheck Summary";
  } else {
    $subject = "PASS: Datacheck Summary";
  }

  my $passed_db = $output{passed_total} == 1 ? 'database' : 'databases';
  my $failed_db = $output{failed_total} == 1 ? 'database' : 'databases';

  my $text = "All datachecks have completed.\n".
    $output{passed_total} . " $passed_db passed all datachecks, ".
    $output{failed_total} . " $failed_db failed one or more datachecks.\n";

  my $tag = $output{tag};
  if (defined $tag) {
    $subject .= " ($tag)";
    $text    .= "Submission tag: $tag\n";
  }
  $self->param('subject', $subject);

  $text .= "Details:\n$db_text";

  my $history_file = $output{history_file};
  if (defined $history_file) {
    $text .= "The datacheck results were stored in a history file: $history_file.\n";
  } else {
    $text .= "The datacheck results were not stored in a history file.\n";
  }

  my $output_dir = $output{output_dir};
  if (defined $output_dir) {
    $text .= "The full output of the datachecks were stored in: $output_dir.\n";
  } else {
    $text .= "The full output of the datachecks were not stored.\n";
  }

  $self->param('text', $text);
}

1;
  
