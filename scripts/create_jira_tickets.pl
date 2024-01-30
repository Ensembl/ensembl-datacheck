#!/usr/bin/env perl

=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=cut

=head2 DESCRIPTION

This script parses the output from Ensembl's Datachecks and creates JIRA tickets
for each failure.

=head1 SYNOPSIS

perl create_jira_tickets.pl [options]

=head1 OPTIONS

=over 8

=item B<-i[nput]> F<datacheck_TAP_file>

Mandatory. Path to a datacheck output TAP file.

=item B<-r[elease]> <release>

Mandatory. Ensembl release version.

=item B<-p[roject]> <JIRA_project>

Mandatory. JIRA project name, e.g. 'ENSPROD'.

=item B<-user> <JIRA_user>

Optional. JIRA username. If not given, uses environment variable $USER 
as default.

=item B<-components> <JIRA_component(s)>

Optional. JIRA component tags. Multiple values can be given as separate 
-components parameters, or as a single comma-separated string.

=item B<-priority> <JIRA_priority>

Optional. JIRA priority given to each ticket. By default, 'Blocker'.

=item B<-dry_run>, B<-dry-run>

In dry-run mode, the JIRA tickets will not be submitted to the JIRA
server. By default, dry-run mode is off.

=item B<-h[elp]>

Print usage information.

=back

=cut


use warnings;
use strict;

use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use Pod::Usage;
use POSIX;

use Bio::EnsEMBL::Compara::Utils::JIRA;

my ( $dc_file, $release, $project, $user, @components, $priority, $dry_run, $help );
$dry_run = 0;
$help    = 0;
GetOptions(
    "i|input=s"       => \$dc_file,
    "r|release=s"     => \$release,
    "p|project=s"     => \$project,
    "user=s",         => \$user,
    "components:s"    => \@components,
    "priority=s"      => \$priority,
    'dry_run|dry-run' => \$dry_run,
    "h|help"          => \$help,
);
pod2usage(1) if $help;
die "Cannot find $dc_file - file does not exist" unless -e $dc_file;
die pod2usage(1) if (! ($dc_file && $release && $project));
# Get file absolute path and basename
my $dc_abs_path = abs_path($dc_file);
my $dc_basename = fileparse($dc_abs_path, qr{\.[a-zA-Z0-9_]+$});
# Get timestamp that will be included in the summary of each JIRA ticket
my $timestamp = strftime("%d-%m-%Y %H:%M:%S", localtime time);
# Get a new Utils::JIRA object to create the tickets for the given division and
# release
my $jira_adaptor = Bio::EnsEMBL::Compara::Utils::JIRA->new(
    -USER     => $user,
    -DIVISION => '',  # defined to avoid using $ENV{'COMPARA_DIV'} (default)
    -RELEASE  => $release,
    -PROJECT  => $project
);
# Parse Datacheck information from input TAP file
my $testcase_failures = parse_datachecks($dc_file, $timestamp);
# Create initial ticket for datacheck run - failures will become subtasks of this
my $dc_task_json_ticket = [{
    assignee    => $jira_adaptor->{_user},
    summary     => "$dc_basename ($timestamp)",
    description => "Datacheck failures raised on $timestamp\nFrom file: $dc_abs_path",
}];
# Create subtask tickets for each datacheck failure
my @json_subtasks;
foreach my $testcase ( keys %$testcase_failures ) {
    my $failure_subtask_json = {
        summary     => $testcase,
        description => $testcase_failures->{$testcase},
    };
    push(@json_subtasks, $failure_subtask_json);
}
# Add subtasks to the initial ticket
$dc_task_json_ticket->[0]->{subtasks} = \@json_subtasks;
# Create all JIRA tickets
my $dc_task_keys = $jira_adaptor->create_tickets(
    -JSON_OBJ         => $dc_task_json_ticket,
    -DEFAULT_PRIORITY => $priority || 'Blocker',
    -EXTRA_COMPONENTS => \@components,
    -DRY_RUN          => $dry_run
);

sub parse_datachecks {
    my ($dc_file, $timestamp) = @_;
    open(my $dc_fh, '<', $dc_file) or die "Cannot open $dc_file for reading";
    my ($test, $group, $testcase, $dc_failures);
    while (my $line = <$dc_fh>) {
        # Remove any spaces/tabs at the end of the line
        $line =~ s/\s+$//;
        # Get the main test name
        if ($line =~ /^# Subtest: (\w+)$/) {
            $test = $1;
            $group = '';
            next;
        }
        # Get the group name it is being applied to
        if ($line =~ /^    # Subtest: (\w+)$/) {
            $group = $1;
            next;
        }
        # Get the test case number and summary that has failed
        if ($line =~ /^[ ]{8}not ok (\d+) - (.+)$/) {
            $testcase = $test . (${group} ? ".${group}" : '') . " subtest $1 ($timestamp)";
            $dc_failures->{$testcase} = "{code:title=$2}\n";
            next;
        }
        # Save all the information provided about the failure
        if ($line =~ /^[ ]{8}#   (.+)$/) {
            $dc_failures->{$testcase} .= "$1\n";
        }
    }
    close($dc_fh);
    # Close all code blocks created
    foreach my $testcase ( keys %$dc_failures ) {
        $dc_failures->{$testcase} .= "{code}\n";
    }
    return $dc_failures;
}
