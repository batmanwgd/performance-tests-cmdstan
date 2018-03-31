#!/bin/bash

usage() {
    echo "=====!!!WARNING!!!===="
    echo "This will clean all repos involved! Use only on a clean checkout."
    echo "$0 <git-hash-1> <git-hash-2> <directories of models> '<extra args for runPerformanceTests.py>''"
}

write_makelocal() {
    echo "CXXFLAGS += -march=core2" > make/local
}

source clean.sh

clean_checkout() {
    pushd cmdstan; git checkout "$1"; popd
    make clean
    pushd cmdstan
    dirty=$(git status --porcelain)
    if [ "$dirty" != "" ]; then
        echo "ERROR: Git repo isn't clean - I'd recommend you make a separate recursive clone of CmdStan for this."
        exit
    fi
    write_makelocal
    popd
}

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    usage
    exit
fi

set -e -x

clean_checkout "$1"
./runPerformanceTests.py -j8 --runj 5 --overwrite-golds $4 $3

for i in performance.*; do
    mv $i "${1}_${i}"
done

clean_checkout "$2"
./runPerformanceTests.py -j8 --runj 5 --check-golds-exact 1e-8 $4 $3
./comparePerformance.py "${1}_performance.csv" performance.csv
