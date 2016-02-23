#! /bin/bash

if [ "$#" -ne 1 ];
then
	echo "Illegal number of parameters"
	exit -1
fi

source builder.sh

POOL=$1

#create_storage_pool $(pwd)/zroot.fs zroot 5000

./freebsd-minimal-recipe.sh ${POOL}
./freebsd-recipe.sh ${POOL}
#freebsd-ghc.sh
