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

=head1 SYNOPSIS

perl create_index.pl [options]

=head1 OPTIONS

=over 8

=item B<-d[atacheck_dir]> <datacheck_dir>

The directory containing the datacheck modules. Defaults to the repository's
default value (lib/Bio/EnsEMBL/DataCheck/Checks). 
Mandatory if -index_file is specified.

=item B<-i[ndex_file]> <index_file>

The path to the index_file that will be created/updated. Defaults to the
repository's default value (lib/Bio/EnsEMBL/DataCheck/index.json). 
Mandatory if -datacheck_dir is specified.

=item B<-h[elp]>

Print usage information.

=back

=cut

use warnings;
use strict;
use feature 'say';

use Bio::EnsEMBL::DataCheck::Manager;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;

my ($help, $datacheck_dir, $index_file);

GetOptions(
  "help!",           \$help,
  "datacheck_dir:s", \$datacheck_dir,
  "index_file:s",    \$index_file,
);

pod2usage(1) if $help;

# It doesn't make sense to update the default index file if a datacheck_dir
# is specified (and vice versa); one wants the default directory and index
# to remain in sync.
if (defined $datacheck_dir && ! defined $index_file) {
  die "index_file is mandatory if datacheck_dir is specified";
}
if (! defined $datacheck_dir && defined $index_file) {
  die "datacheck_dir is mandatory if index_file is specified";
}

my %manager_params;
$manager_params{datacheck_dir} = $datacheck_dir if defined $datacheck_dir;
$manager_params{index_file}    = $index_file    if defined $index_file;

my $manager = Bio::EnsEMBL::DataCheck::Manager->new(%manager_params);

$manager->write_index();
