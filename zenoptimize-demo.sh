#!/bin/bash

N=$1

if [ -z $N ]; then N=500000; fi

rm -rf ~/.ruby_inline
sync; sync; sync
export GEM_SKIP=ParseTree:RubyInline

echo running $N iterations of factorial demo:
echo
echo "ruby: (time ruby factorial.rb $N)"
time ruby factorial.rb $N
echo
echo "zenspider: (time ruby -rzenoptimize factorial.rb $N)"
time ruby -I.:../../ParseTree/dev/lib:../../RubyInline/dev:../../ruby_to_c/dev -rzenoptimize factorial.rb $N