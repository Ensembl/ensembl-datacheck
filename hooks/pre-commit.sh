#!/bin/sh
#
# Most commits in this repository will be adding or updating datachecks.
# It is important to keep the index in-sync with the datacheck metadata;
# this is simple to do, but easy to forget, so an ideal candidate for
# automation...

EXIT_STATUS=0

# Stash any changes that aren't part of this commit, otherwise
# the index would be synced with things we're not committing! 
git stash -q --keep-index

echo "CHECKING INDEX..."
if !(perl t/index.t)
then
  echo "UPDATING INDEX..."
  if (perl scripts/create_index.pl)
  then
    git add lib/Bio/EnsEMBL/DataCheck/index.json
  else
    echo "COMMIT REJECTED: failed to update index."
    echo "Force the commit with the --no-verify flag (not recommended)."
    EXIT_STATUS=1
  fi
fi

git stash pop -q

exit $EXIT_STATUS
