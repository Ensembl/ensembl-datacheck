# Copyright [2018] EMBL-European Bioinformatics Institute
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

use Bio::EnsEMBL::DataCheck::CompareDbCheck;
use Test::More;

# Note that you cannot, by design, create a BaseCheck object; datachecks
# must inherit from it and define mandatory, read-only parameters that
# are specific to that particular datacheck. So there's a limited amount
# of testing that we can do on the base class, the functionality is
# tested on a subclass.

my $module = 'Bio::EnsEMBL::DataCheck::CompareDbCheck';

diag('Attributes');
can_ok($module, qw(compare_dba));

done_testing();
