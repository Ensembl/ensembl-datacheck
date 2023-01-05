# Copyright [2018-2023] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;
use feature 'say';

use Bio::EnsEMBL::DataCheck::Manager;

use Path::Tiny;
use Test::More;

my $module = 'Bio::EnsEMBL::DataCheck::Manager';

my $manager = $module->new();
my $index_1 = $manager->read_index();
my $tmp_index_file = Path::Tiny->tempfile();
$manager = $module->new(index_file => "$tmp_index_file");
my $index_2 = $manager->write_index();

is_deeply($index_1, $index_2, 'Index file is up-to-date');

done_testing();
