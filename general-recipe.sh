#! /bin/bash

source builder.sh

POOL=$1

create_storage_pool $(pwd)/zroot.fs zroot 5000

./freebsd-minimal-recipe.sh ${POOL}
./freebsd-recipe.sh ${POOL}
#freebsd-ghc.sh
