package Bio::EnsEMBL::DataCheck::Checks::GeneStableID;

use warnings;
use strict;

use Moose;
use Test::More;
use Bio::EnsEMBL::DataCheck::Test::DataCheck;

extends 'Bio::EnsEMBL::DataCheck::DbCheck';

use constant {
    NAME        => 'GeneStableID',
    DESCRIPTION => 'Genes, transcripts, exons and translations have non-NULL, unique stable IDs and consistent ID base prefixes',
    GROUPS      => ['core', 'brc4_core', 'geneset'],
    DB_TYPES    => ['core'],
    TABLES      => ['coord_system', 'exon', 'gene', 'seq_region', 'transcript', 'translation']
};

sub tests {
    my ($self) = @_;
    my $species_id = $self->dba->species_id;

    $self->stable_id_check('gene',       $species_id);
    $self->stable_id_check('transcript', $species_id);
    $self->stable_id_check('exon',       $species_id);
    $self->translation_stable_id_check($species_id);

    # NEW: check base prefix consistency across feature types
    $self->stable_id_prefix_consistency_check($species_id);
}

sub stable_id_check {
    my ($self, $table, $species_id) = @_;

    my $desc_1 = $table.' table has non-NULL stable IDs';
    my $diag_1 = "Null $table.stable_id";
      my $sql_1  = qq/
    SELECT $table.stable_id FROM
      $table INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE cs.species_id = $species_id
      AND $table.stable_id IS NULL
	  /;
    is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

    my $desc_2 = $table.' table has unique stable IDs';
    my $diag_2 = "Duplicate $table.stable_id";
      my $sql_2  = qq/
    SELECT $table.stable_id FROM
      $table INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE cs.species_id = $species_id
    GROUP BY $table.stable_id
    HAVING COUNT(*) > 1
	  /;
    is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);
}

sub translation_stable_id_check {
    my ($self, $species_id) = @_;

    my $desc_1 = 'translation table has non-NULL stable IDs';
    my $diag_1 = "Null translation.stable_id";
      my $sql_1  = qq/
    SELECT tn.stable_id FROM
      translation tn INNER JOIN
      transcript tt USING (transcript_id) INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE cs.species_id = $species_id
      AND tn.stable_id IS NULL
	  /;
    is_rows_zero($self->dba, $sql_1, $desc_1, $diag_1);

    my $desc_2 = 'translation table has unique stable IDs';
    my $diag_2 = "Duplicate translation.stable_id";
      my $sql_2  = qq/
    SELECT tn.stable_id FROM
      translation tn INNER JOIN
      transcript tt USING (transcript_id) INNER JOIN
      seq_region sr USING (seq_region_id) INNER JOIN
      coord_system cs USING (coord_system_id)
    WHERE cs.species_id = $species_id
      AND cs.name <> 'lrg'
    GROUP BY tn.stable_id
    HAVING COUNT(*) > 1
	  /;
    is_rows_zero($self->dba, $sql_2, $desc_2, $diag_2);
}

# -------------------------------
# NEW: prefix consistency checker
# -------------------------------
sub stable_id_prefix_consistency_check {
    my ($self, $species_id) = @_;

    my %tables = (
	gene       => 'G',
	transcript => 'T',
	exon       => 'E',
	translation=> 'P',
	);

    my %prefixes_by_table;
    for my $table (keys %tables) {
	$prefixes_by_table{$table} = $self->get_base_prefixes_for_table($table, $species_id, $tables{$table});
    }

    # Union of all base prefixes observed across all feature types
    my %union;
    for my $table (keys %prefixes_by_table) {
	$union{$_}++ for @{$prefixes_by_table{$table}};
    }
    my @all_prefixes = sort keys %union;

    my $desc = 'Stable ID base prefix is consistent across genes, transcripts, exons and translations';
    my $ok = @all_prefixes <= 1;

    # If not OK, provide diagnostics by table
    unless ($ok) {
	my $diag = "Observed base prefixes per table:\n";
	for my $table (sort keys %prefixes_by_table) {
	    my @vals = @{$prefixes_by_table{$table}};
	    @vals = ('<none>') unless @vals;
	    $diag .= sprintf("  %-12s : %s\n", $table, join(', ', sort @vals));
	}
	diag($diag);
    }

    ok($ok, $desc);
}

# Helper: collect DISTINCT base prefixes for a table.
# Base prefix: (letters/underscore)* BEFORE the feature-type letter (G/T/E/P) that precedes the numeric part.
# We strip any ".version" first (in SQL), then use Perl regex to normalise.
sub get_base_prefixes_for_table {
    my ($self, $table, $species_id, $feature_letter) = @_;

    my $sql;
    if ($table eq 'translation') {
	# translation -> transcript -> seq_region -> coord_system
	    $sql = qq/
      SELECT DISTINCT SUBSTRING_INDEX(tn.stable_id, '.', 1) AS sid
      FROM translation tn
        INNER JOIN transcript tt USING (transcript_id)
        INNER JOIN seq_region sr USING (seq_region_id)
        INNER JOIN coord_system cs USING (coord_system_id)
      WHERE cs.species_id = $species_id
        AND tn.stable_id IS NOT NULL
		/;
    } else {
	# gene, transcript, exon all carry seq_region_id
	    $sql = qq/
      SELECT DISTINCT SUBSTRING_INDEX($table.stable_id, '.', 1) AS sid
      FROM $table
        INNER JOIN seq_region sr USING (seq_region_id)
        INNER JOIN coord_system cs USING (coord_system_id)
      WHERE cs.species_id = $species_id
        AND $table.stable_id IS NOT NULL
		/;
    }

    my $dbh = $self->dba->dbc->db_handle;
    my $sth = $dbh->prepare($sql);
    $sth->execute();

    my %seen;
    while (my ($sid) = $sth->fetchrow_array) {
	next unless defined $sid && $sid ne '';

	# drop trailing digits and optional feature-type letter; ignore version (already stripped in SQL)
	$sid =~ s/\d+$//;       # ENSG00000123 -> ENSG
	$sid =~ s/[GTEP]$//i;   # remove trailing feature-type letter (G/T/E/P), if present

	$seen{$sid}++ if $sid ne '';
    }

    return [ sort keys %seen ];
}


1;
