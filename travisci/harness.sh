#!/bin/bash

export PERL5LIB=$PWD/lib:$PWD/ensembl/modules:$PWD/ensembl-funcgen/modules:$PWD/ensembl-hive/modules:$PWD/ensembl-metadata/modules:$PWD/ensembl-test/modules:$PWD/ensembl-variation/modules:$PWD/bioperl-live-release-1-6-924

if [ "$DB" = 'mysql' ]; then
    (cd t && ln -sf MultiTestDB.conf.mysql MultiTestDB.conf)
else
    echo "Don't know about DB '$DB'"
    exit 1;
fi

echo "Running test suite"
if [ "$COVERALLS" = 'true' ]; then
  PERL5OPT='-MDevel::Cover=+ignore,bioperl,^ensembl,Bio/EnsEMBL/DataCheck/Checks/' perl $PWD/ensembl-test/scripts/runtests.pl -verbose t $SKIP_TESTS
else
  perl $PWD/ensembl-test/scripts/runtests.pl t $SKIP_TESTS
fi

rt=$?
if [ $rt -eq 0 ]; then
  if [ "$COVERALLS" = 'true' ]; then
    echo "Running Devel::Cover coveralls report"
    cover --nosummary -report coveralls
  fi
  exit $?
else
  exit $rt
fi
