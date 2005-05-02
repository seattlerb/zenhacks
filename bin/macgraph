#!/bin/bash

# set -x

PATH=$PATH:/Applications/Graphviz.app/Contents/MacOS/

f1=/tmp/graph.$$.dot
f2=/tmp/graph.$$.pdf
if [ $1 == '-f' ]; then
    shift 1
    echo $* | GEM_SKIP=ParseTree ruby -Ilib bin/parse_tree_graph -f -a > $f1
else
    GEM_SKIP=ParseTree ruby -Ilib bin/parse_tree_graph $* > $f1
fi
dot -Tepdf $f1 > $f2
open $f2
(sleep 10; rm -f $f1 $f2) &

