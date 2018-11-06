=head1 LICENSE

Copyright [2018] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::DisplaybleGenes;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Utils qw/sql_count/;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
  NAME           => 'DisplaybleGenes',
  DESCRIPTION    => 'Check that genes are displayable and '
    . 'have web_data attached to their analysis.',
  GROUPS         => ['core_handover'],
  DATACHECK_TYPE => 'advisory',
  DB_TYPES       => ['core', 'otherfeatures', 'rnaseq', 'cdna'],
  TABLES         => ['gene', 'analysis', 'analysis_description']
};

sub tests {
  my ($self) = @_;

# It's quite easy to add genes but not get the display correct.
# highlight any analysis linked to the gene.analysis_id
# that has either analysis_description.displayable = 0 or
# analysis_description.web_data = NULL.

# If there is no web_data, it is most likely an error. Similarly, if displayable=0, those genes won't appear at all; in which case what are they doing there? (Although, maybe there was a last-minute decision not to display them, and this is the easiest way to do that, which is why it would be an advisory datacheck.)

# So, if a gene analysis has no webdata, fail. Likewise, displayable=0, fail.

  sub skip_tests {
    my ($self) = @_;

    my $sql = 'SELECT COUNT(*) FROM analysis_description';

    if (! sql_count($self->dba, $sql) ) {
      return (1, 'No analysis_description');
    }
  }

  my $sql = q/
    SELECT COUNT(gene_id)
      FROM analysis, gene, analysis_description
     WHERE gene.analysis_id = analysis.analysis_id
       AND analysis.analysis_id = analysis_description.analysis_id
       AND analysis_description.web_data is not NULL
       AND analysis_description.displayable = 0
  /;

  my $desc = 'All genes are displayed correctly.';
  is_rows_zero($self->dba, $sql, $desc);
}


1;

