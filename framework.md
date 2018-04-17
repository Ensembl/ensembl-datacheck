# `Bio::EnsEMBL::DataCheck` Framework
`ensembl-datacheck` uses a set of base modules and scripts to define and execute tests using the `Test::More` suite.

## Modules

###`Bio::EnsEMBL::DataCheck::BaseCheck`

`BaseCheck` defines the minimal code needed for a test. All datachecks inherit from this module and provide values for the following attributes:
* `name` - (required) name of the test
* `description` - (required) description of the test
* `datacheck_type` - (required) datachecks are "critical" (default) or "advisory"
* `groups` - (optional) list of groups to which the datacheck belongs

Instances of this test are invoked by `run` which uses `Test::More` to return test results in standard TAP format.

###`Bio::EnsEMBL::DataCheck::DbCheck`
`DbCheck` supports tests that deal with Ensembl database adaptors. The following variables can be set:
* `db_types` - (optional) list of Ensembl database types that the test applies to (core, variation, otherfeatures, compara, funcgen)
* `tables` - (optional) list of tables that are related to the datacheck
* `per_db` - (optional) whether the datacheck runs on a whole database rather than individual species

After the test runs, the database adaptor is disconnected to avoid connection leaks.

###`Bio::EnsEMBL::DataCheck::CompareDbCheck`
`CompareDbCheck` is an extension of `DbCheck` that supports tests that take two DBAs for comparison (e.g. old and new databases, or master and slave databases). 

###`Bio::EnsEMBL::DataCheck::Manager`
The `Manager` module can be used to retrieve a set of datachecks, and optionally run them in a test harness. The history of datachecks' pass/fail status can be read from and written to a file, in order for datachecks to determine if the need to be run.

###`Bio::EnsEMBL::DataTest::Utils::DBUtils`
This module contains `Test::More`-style methods for dealing with Ensembl databases, e.g. `rows` for checking the number of rows returned.

## Scripts

### `run_tests.pl`
This script runs one or more datachecks for the specified database e.g.
```
perl -I lib/ scripts/run_tests.pl
  -groups core_handover 
  -history_file /path/to/history/file
  -host localhost -port 3306 -user anonymous 
  -dbname schizosaccharomyces_pombe_core_39_92_2
```

### `create_datacheck.pl`
This script generates a datacheck file in a standard format, such that only the tests method (and optionally the skip_tests method) then need to be written e.g.
```
perl -I lib/ scripts/create_datacheck.pl 
  -name AssemblyAccession 
  -description 'Meta key "assembly.accession" is set.' 
  -db_types core 
  -tables 'meta'
```