use strict;
use warnings;

use FindBin; FindBin::again();
use Test::Tester;
use Test::More;

use Bio::EnsEMBL::DataCheck::Checks::SampleGeneInAnnotation;
use Bio::EnsEMBL::Test::MultiTestDB;

my $testdb = Bio::EnsEMBL::Test::MultiTestDB->new('drosophila_melanogaster', $FindBin::Bin);
my $dba = $testdb->get_DBAdaptor('core');
my $dbh = $dba->dbc->db_handle;
my $species_id = $dba->species_id;
my $sample_gene = 'FBgn0263441';
my $meta_key = 'genebuild.sample_gene';

sub set_meta {
  my ($value) = @_;
  $dbh->do("DELETE FROM meta WHERE species_id = ? AND meta_key = ?", undef, $species_id, $meta_key);
  if (defined $value) {
    $dbh->do("INSERT INTO meta (species_id, meta_key, meta_value) VALUES (?, ?, ?)", undef,
      $species_id, $meta_key, $value);
  }
}

sub check_result {
  my ($expected, $description) = @_;
  my $check = Bio::EnsEMBL::DataCheck::Checks::SampleGeneInAnnotation->new(dba => $dba);
  check_tests(
    sub { $check->tests },
    [ map { { ok => $_, depth => undef } } @$expected ],
    $description
  );
}

set_meta($sample_gene);
check_result([1, 1], 'matching genebuild.sample_gene passes');

set_meta(undef);
check_result([0, 1], 'missing genebuild.sample_gene fails');

$dbh->do('ALTER TABLE meta MODIFY meta_value varchar(255) NULL');
$dbh->do("INSERT INTO meta (species_id, meta_key, meta_value) VALUES (?, ?, NULL)", undef,
  $species_id, $meta_key);
check_result([0, 1], 'NULL genebuild.sample_gene fails');

set_meta($sample_gene);
$dbh->do("INSERT INTO meta (species_id, meta_key, meta_value) VALUES (?, ?, ?)", undef,
  $species_id, $meta_key, 'FBgn0000000');
check_result([0, 0], 'duplicate genebuild.sample_gene values fail');

set_meta('FBgn0000000');
check_result([1, 0], 'genebuild.sample_gene absent from gene.stable_id fails');

# The new check only joins meta to gene, so analysis_description.web_data has
# no bearing on its result. A valid sample gene therefore passes regardless of
# the analysis display metadata used by DisplayableSampleGene.
set_meta($sample_gene);
check_result([1, 1], 'valid sample gene result is independent of web_data');

set_meta(undef);
$dbh->do('ALTER TABLE meta MODIFY meta_value varchar(255) NOT NULL');

done_testing();
