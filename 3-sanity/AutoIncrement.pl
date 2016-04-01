
=head1 NAME

  AutoIncrement - A sanity test (type 3 in the healthcheck system).

=head1 SYNOPSIS

  $ perl AutoIncrement.pl 'human' 'core'

=head1 DESCRIPTION

  ARG[Species name]     : String - Name of the species to test on.
  ARG[Database type]    : String - Database type to test on.

  Database type         : Core databases (user input).

Certain columns in the core tables should have the AUTO_INCREMENT flag set. This healthchecks retrieves
meta information for those columns to check that this is the case.

Perl adaptation of the AutoIncrement.java test.
See: https://github.com/Ensembl/ensj-healthcheck/blob/bb8a7c3852206049087c52c5b517766eef555c7d/src/org/ensembl/healthcheck/testcase/generic/AutoIncrement.java
 
=cut

#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Getopt::Long;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::SqlHelper;

my $registry = 'Bio::EnsEMBL::Registry';

my ($species, $database_type);

my $parent_dir = File::Spec->updir;
my $file = $parent_dir . "/config";

my $config = do $file;
if(!$config){
    warn "couldn't parse $file: $@" if $@;
    warn "couldn't do $file: $!"    unless defined $config;
    warn "couldn't run $file"       unless $config; 
}
else {
    $registry->load_registry_from_db(
        -host => $config->{'db_registry'}{'host'},
        -user => $config->{'db_registry'}{'user'},
        -port => $config->{'db_registry'}{'port'},
    );
    #if there is command line input use that, else take the config file.
    GetOptions('species:s' => \$species, 'type:s' => \$database_type);
    if(!defined $species){
        $species = $config->{'species'};
    }
    if(!defined $database_type){
        $database_type = $config->{'database_type'};
    }
    print "$species $database_type \n";
} 

my $dba = $registry->get_DBAdaptor($species, $database_type);

my $helper = Bio::EnsEMBL::Utils::SqlHelper->new(
   -DB_CONNECTION => $dba->dbc()
);

my $result = 1;

#These are all the columns that should have autoincrement set.
my @columns = ("alt_allele.alt_allele_id", "analysis.analysis_id", "assembly_exception.assembly_exception_id", 
               "attrib_type.attrib_type_id", "coord_system.coord_system_id", "data_file.data_file_id",  
               "density_feature.density_feature_id", "density_type.density_type_id", "ditag.ditag_id", 
               "ditag_feature.ditag_feature_id", "dna_align_feature.dna_align_feature_id", "exon.exon_id", 
               "external_db.external_db_id", "gene.gene_id", "intron_supporting_evidence.intron_supporting_evidence_id", 
               "karyotype.karyotype_id", "map.map_id", "mapping_session.mapping_session_id", "marker.marker_id", 
               "marker_feature.marker_feature_id", "marker_synonym.marker_synonym_id", "meta.meta_id", 
               "misc_feature.misc_feature_id", "misc_set.misc_set_id", "object_xref.object_xref_id", 
               "operon.operon_id", "peptide_archive.peptide_archive_id", "prediction_exon.prediction_exon_id",
               "prediction_transcript.prediction_transcript_id", "protein_align_feature.protein_align_feature_id", 
               "protein_feature.protein_feature_id", "repeat_consensus.repeat_consensus_id", 
               "repeat_feature.repeat_feature_id", "seq_region.seq_region_id", "seq_region_synonym.seq_region_synonym_id", 
               "simple_feature.simple_feature_id", "transcript.transcript_id", "translation.translation_id",
               "unmapped_object.unmapped_object_id", "unmapped_reason.unmapped_reason_id", "xref.xref_id");

#Get the database name. We need this for our query.
my $dbname = ($dba->dbc())->dbname();

foreach my $part (@columns){
    #split to get both table and column names.
    my @tablecolumn = split(/\./, $part);
    my $table = $tablecolumn[0];
    my $column = $tablecolumn[1];

    #this query will return column info, including whether it is auto incremented.
    my $sql = "SHOW COLUMNS FROM " . $table . " IN " . $dbname . " WHERE field = '" . $column . "'";

    my $query_result = $helper->execute(
        -SQL => $sql,
    );

    foreach my $nested_array (@$query_result){
        #loook for 'aut_increment'  in results and push it in an array.	    
        my @auto_increment;

                foreach my $cell (@$nested_array){
                    if(defined $cell){
                        if($cell eq 'auto_increment'){
                            push @auto_increment, $cell;
                        }
                     }
                }

            #... if the array is empty, autoincrement has not been declared for this column!
            if(!@auto_increment){
                print "PROBLEM: " . $table . "." . $column . "  is not set to autoincrement! \n";
                $result &= 0;
            }
            
    }
       
}

#print this for now.
print $result . "\n";

