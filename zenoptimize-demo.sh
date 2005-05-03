#!/bin/bash

N=$1

if [ -z $N ]; then N=500000; fi
if [ -z $2 ]; then SKIP=no; else SKIP=yes; fi

rm -rf ~/.ruby_inline
sync; sync; sync
export GEM_SKIP=ParseTree:RubyInline

echo running $N iterations of factorial demo:
echo

if [ $SKIP = no ]; then
    echo "ruby: (time ruby factorial.rb $N)"
    time ruby misc/factorial.rb $N
    echo
fi

echo "zenspider: (time ruby -rzenoptimize factorial.rb $N)"
time ruby -I.:lib:../../ParseTree/dev/lib:../../RubyInline/dev:../../ruby_to_c/dev -rzenoptimize misc/factorial.rb $N