=head1 LICENSE

Copyright [2018-2023] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::TimelySemaphoreRelease;

use warnings;
use strict;

use Moose;
use Test::More;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'TimelySemaphoreRelease',
  DESCRIPTION    => 'Check that every semaphored job was started only after all of its fan jobs had completed.',
  GROUPS         => ['compara_gene_tree_pipelines'],
  DATACHECK_TYPE => 'critical',
  DB_TYPES       => ['compara'],
  TABLES         => ['job', 'semaphore']
};

sub tests {
    my ($self) = @_;
 
    my $sql = q{
        SELECT
            job.job_id AS job_id,
            job.when_completed,
            semaphore.semaphore_id,
            dependent_job_id,
            dep_job.when_completed AS dep_completed,
            dep_job.runtime_msec AS dep_runtime_msec,
            CEILING(
                (
                    TIMESTAMPDIFF(SECOND, job.when_completed, dep_job.when_completed)
                    - (dep_job.runtime_msec / 1000)
                )
            ) AS delta
        FROM
            job
        JOIN
            semaphore ON job.controlled_semaphore_id = semaphore.semaphore_id
        JOIN
            job AS dep_job ON semaphore.dependent_job_id = dep_job.job_id
        HAVING
            delta < 0;
    };
    my $helper  = $self->dba->dbc->sql_helper;
    my $array   = $helper->execute(-SQL => $sql, USE_HASHREFS => 1);

    if(scalar @$array > 0) {
        my @msg = ("job_id\twhen_completed\tsemaphore_id\tdependent_job_id\tdep_completed\tdep_runtime_msec\tdelta\n");
        foreach my $elem (@$array) {
            push @msg, "$elem->{job_id}\t$elem->{when_completed}\t$elem->{semaphore_id}\t$elem->{dependent_job_id}" . 
            "\t$elem->{dep_completed}\t$elem->{dep_runtime_msec}\t$elem->{delta}\n";
        }
        diag(@msg);
    }

    my $test_name = "Semaphores were released in a timely manner.";
    is(scalar @$array, 0 , $test_name);
}

1;

