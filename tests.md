# Current datachecks

## Integrity checks

Integrity checks are checks that indicate a significant problem with a database that must be fixed before further processing. These include tests of data integrity, minimal levels of annotation, syntactic correctness etc. If a test indicates a failure that should be allowed to pass, there is either a problem with the test or the underlying schema.

### Core database integrity checks
* [assembly_exceptions.t](t/integrity/core/assembly_exceptions.t) - check if assembly_exceptions are present and correct
* [assembly_mapping.t](t/integrity/core/assembly_mapping.t) - check vality of assembly mappings
* [core_foreign_keys.t](t/integrity/core/core_foreign_keys.t) - check for incorrect or missing foreign keys between tables
* [lrg.t](t/integrity/core/lrg.t) - check that LRG features and seq_regions are correctly associated
* [sequence_level.t](t/integrity/core/sequence_level.t) - check that DNA is attached and only attached to sequence-level seq_regions
* [xref_types.t](t/integrity/core/xref_types.t) - check that xrefs are only attached to one feature type

## Comparison checks

Comparison checks compare the contents of two databases and alert the user to differences. Comparison checks either indicate where a table is out of sync with its master (e.g. otherfeatures vs core) or where the contents of a table has reduced in size between releases (e.g. loss of xrefs)

### Core database comparison checks
* [compare_previous_biotypes.t](t/comparison/core/compare_previous_biotypes.t) - check that the numbers of genes with different biotypes has not dropped by less than 75% between versions of databases

## Sanity checks

Sanity checks are designed to alert database developers to potential problems with the contents of a database which whilst having a valid data structure may indicate problems with the underlying data. For instance, a gene with very large introns may be validly represented in a database but indicate problems with the annotation.

Sanity checks are not usually run after handover and failure of sanity checks is no barrier to release of a database.

_None implemented at present_