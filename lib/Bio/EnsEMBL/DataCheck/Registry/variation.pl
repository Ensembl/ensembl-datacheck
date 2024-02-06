use strict;
use warnings;
use Bio::EnsEMBL::Registry;

# Metadata
Bio::EnsEMBL::Registry->load_registry_from_url("$METADATA_URI/$METADATA_DB?species=multi&group=metadata");
# Production
Bio::EnsEMBL::Registry->load_registry_from_url("$PRODUCTION_URI/$PRODUCTION_DB?species=multi&group=production");
# Taxonomy
Bio::EnsEMBL::Registry->load_registry_from_url("$TAXONOMY_URI/$TAXONOMY_DB?species=multi&group=taxonomy");
# Regulation
my $funcgen_db=$DB_NAME;
$funcgen_db =~ s/variation/funcgen/r;
Bio::EnsEMBL::Registry->load_registry_from_url("$SRC_URI/$funcgen_db?species=$SPECIES&group=funcgen");
# DB to checks
# TODO add loop over list of DBs
Bio::EnsEMBL::Registry->load_registry_from_url("$SRC_URI/$DB_NAME?species=$SPECIES&group=variation");

1;