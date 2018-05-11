# Copyright [2018] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use warnings;
use strict;
use feature 'say';

use Bio::EnsEMBL::DataCheck::Manager;

use Getopt::Long qw(:config no_ignore_case);

my ($datacheck_dir, $index_file);

GetOptions(
  "datacheck_dir:s", \$datacheck_dir,
  "index_file=s",    \$index_file,
);

my %manager_params;
$manager_params{datacheck_dir} = $datacheck_dir if defined $datacheck_dir;
$manager_params{index_file}    = $index_file    if defined $index_file;

my $manager = Bio::EnsEMBL::DataCheck::Manager->new(%manager_params);

$manager->write_index();
