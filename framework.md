# `Bio::EnsEMBL::DataTest` Framework
`ensembl-datacheck` uses a set of base modules and scripts to define and execute tests using the `Test::More` library.

## Modules

###`Bio::EnsEMBL::DataTest::BaseTest`

`BaseTest` defines the minimal code needed for a test. Tests instantiate this module and provide the following instance variables:
* `name` - name of the test
* `test` - reference to code run when the test is invoked. This should use `Test::More` style tests.
* `test_predicate` - optional code reference run by `will_test` if the test should be run or not. Returns a hash reference with the keys `run` and `reason`. The default implementation returns `{run=>1}`

Instances of this test are invoked by `run` which uses `Test::More` to capture test results which are returned as a hash with the keys:
* `pass` - overall pass/fail as 1/0
* `details` - array of individual test results
* `log` - detailed output of test
* `skipped` - 1 if test was skipped
* `reason` - reasons for skipping (if skipped set)

###`Bio::EnsEMBL::DataTest::TypeAwareTest`
`TypeAwareTest` supports tests that deal with Ensembl database adaptors. The following instance variables can be set:
* `per_species` - whether this test runs on an individual species or a whole database
* `db_types`  - list of Ensembl database types that the test applies to (core, variation, otherfeatures, compara, funcgen)

`will_test` checks the supplied database adaptor against the supported list to determine whether it will run. After the test runs, the database adaptor is disconnected to avoid connection leaks.

###`Bio::EnsEMBL::DataTest::TableAwareTest`
`TableAwareTest` supports tests that only need to run if defined tables have changed. This requires a hash containing update dates for each table when the test was last run to be passed to `run` as the second argument. This can be generated using `Bio::EnsEMBL::DataTest::Utils::DBUtils::table_dates`.

###`Bio::EnsEMBL::DataTest::Utils::TestUtils`
This module contains the code needed to run a `Test::More`-based test and capture output.

###`Bio::EnsEMBL::DataTest::Utils::DBUtils`
This module contains helper methods for dealing with Ensembl databases.

## Scripts

### `run_tests.pl`
This is a basic script which reads a collection of tests from a location on the file system and applies them to the databases specified.