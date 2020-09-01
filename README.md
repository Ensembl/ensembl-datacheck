[![Coverage Status](https://coveralls.io/repos/github/Ensembl/ensembl-datacheck/badge.svg?branch=master)](https://coveralls.io/github/Ensembl/ensembl-datacheck?branch=master) [![Build Status](https://travis-ci.org/Ensembl/ensembl-datacheck.svg?branch=master)](https://travis-ci.org/Ensembl/ensembl-datacheck)

# ensembl-datacheck
Code for checking Ensembl data
* [Framework details](framework.md)

## Repository dependencies
The datachecks require the following repositories to be checked out and their libraries available in your environment:
* [ensembl](https://github.com/Ensembl/ensembl)
* [ensembl-compara](https://github.com/Ensembl/ensembl-compara)
* [ensembl-funcgen](https://github.com/Ensembl/ensembl-funcgen)
* [ensembl-metadata](https://github.com/Ensembl/ensembl-metadata)
* [ensembl-orm](https://github.com/Ensembl/ensembl-orm)
* [ensembl-variation](https://github.com/Ensembl/ensembl-variation)

## Using git hooks to synchronise the datacheck index
It's easy to get out of sync between datachecks and the index. There's a
test for this, so it would eventually get detected, but we can proactively
avoid the problem with a git hook that automatically updates the index.

To configure this, in your local repository do:
`ln -s hooks/pre-commit.sh .git/hooks/pre-commit`

Then, whenever you commit, the index will be checked, and updated if
necessary. To skip the checking, use the `--no-verify` flag.
