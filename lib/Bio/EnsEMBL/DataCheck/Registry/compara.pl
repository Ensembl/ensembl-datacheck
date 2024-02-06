use strict;
use warnings;
use Bio::EnsEMBL::MetaData::DBSQL::MetaDataDBAdaptor;
use Bio::EnsEMBL::Production::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Taxonomy::DBSQL::TaxonomyDBAdaptor;
use Bio::EnsEMBL::Registry;

# Metadata
Bio::EnsEMBL::Registry->load_registry_from_url("$METADATA_URI/$METADATA_DB?species=multi&group=metadata");
# Production
Bio::EnsEMBL::Registry->load_registry_from_url("$PRODUCTION_URI/$PRODUCTION_DB?species=multi&group=production");
# Taxonomy
Bio::EnsEMBL::Registry->load_registry_from_url("$TAXONOMY_URI/$TAXONOMY_DB?species=multi&group=taxonomy");
# DB to checks
# TODO add loop over list of DBs
Bio::EnsEMBL::Registry->load_registry_from_url("$SRC_URI/$DB_NAME?species=$SPECIES&group=compara");

1;