=head1 LICENSE

Copyright [2018-2022] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::DataCheck::Checks::APPRISCompareSource;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;
use File::Spec;


extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
    NAME           => 'APPRISCompareSource',
    DESCRIPTION    => 'APPRIS load match input data in files',
    GROUPS         => [ 'geneset_support_level' ],
    DATACHECK_TYPE => 'critical',
    DB_TYPES       => [ 'core' ],
    TABLES         => [ 'transcript_attrib' ]
};

sub tests {
    my ($self) = @_;
    SKIP: {

        my $helper = $self->dba->dbc->sql_helper;
        my $mca = $self->dba->get_adaptor('MetaContainer');
        my $assembly_default = $mca->single_value_by_key('assembly.default');
        my $production_name = $mca->get_production_name;
        my $schema_version = $mca->get_schema_version;
        my $file = File::Spec->catfile($ENV{'APPRIS_FILE_PATH'},
        join('.', ucfirst($production_name), $assembly_default, "e" . $schema_version, 'appris_data', 'principal', 'txt'));
        skip 'No APPRIS_FILE_PATH dir set', 1 unless defined($ENV{'APPRIS_FILE_PATH'});

        skip 'No file for current version of database', 1 unless -e $file;
        # TODO manage the extra parameter to pass to the test a `base_path` value.
        # File format : .../Mus_musculus.GRCm38.e93.appris_data.principal.txt
        my $desc_1 = 'APPRIS file content %s match imported transcript_attrib';
        my $sql_1 = q/
            SELECT UPPER(value), count(*)
            FROM transcript_attrib
            JOIN attrib_type a using (attrib_type_id)
            WHERE a.code = 'appris'
            GROUP BY value;/;

        my $attribs_counts = $helper->execute(-SQL => $sql_1);
        my $cut = `cut -f3 $file | sed -r 's/[:]+//g' | sort | uniq -c | awk '{ print \$2 " " \$1}'`;
        my @data = split(/\n/, $cut);
        my @line;
        my %filecounts;
        foreach my $token (@data) {
            @line = split(/ /, $token);
            $filecounts{$line[0]} = $line[1];
        };
        foreach my $attrib_count (@$attribs_counts) {
            my ($code, $count) = @$attrib_count;
            my $detail_desc = sprintf($desc_1, $code);
            is($count, $filecounts{ $code }, $detail_desc);
        }
    }
}

1;