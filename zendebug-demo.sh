#!/bin/bash

VERSION='1.0.0' # this is mainly to appease my relese script's requirements.

export GEM_SKIP=RubyInline

# rm -rf ~/.ruby_inline

type=$1
if [ -z "$1" ]; then
    type=help
fi

N=10000
if [ ! -z "$2" ]; then
    N=$2
fi

if [ $type = "help" ]; then
    echo "usage: $0 type"
    echo "  type ="
    echo "    native       - run factorial with native ruby"
    echo "    debug        - run factorial with ruby debugger"
    echo "    zendebug     - run factorial with zendebugger"
    echo "    profile      - ..."
    echo "    bench        - ..."
    echo "    native-rex   - ..."
    echo "    zendebug-rex - ..."
    echo "    debug-rex    - ..."
    echo "    bench-rex    - ..."
fi

RI=../../RubyInline/dev

if [ $type = "native" ]; then
    yes c | time -p ruby -I$RI misc/factorial.rb $N
fi

if [ $type = "debug" ]; then
    yes c | time -p ruby -rdebug -I$RI misc/factorial.rb $N
fi

if [ $type = "zendebug" ]; then
    yes c | time -p ruby -rzendebug -Ilib:$RI misc/factorial.rb $N
fi

if [ $type = "profile" ]; then
    yes c | time -p ruby -rprofile -rzendebug -Ilib:$RI misc/factorial.rb 500
fi

if [ $type = "bench" ]; then
    echo "N=$N"
    for type in native zendebug debug; do
	echo -n "$type: "
	for M in 1 2 3 4 5; do
	    ./zendebug-demo.sh $type $N 2>&1 | ruby -nae 'puts $F[1] if /real/'
	done | add -m
    done
fi

############################################################

if [ $N = "10000" ]; then
    N=2
fi

if [ $type = "native-rex" ]; then
#    (cd rexml_3.1.1/benchmarks/; yes c | ruby -I../../$RI comparison.rb $N)
    (cd rexml_3.1.1/benchmarks/; yes c | ruby -I..:../../$RI bench.rb $N)
fi

if [ $type = "zendebug-rex" ]; then
    (cd rexml_3.1.1/benchmarks/; yes c | ruby -I../../$RI:../../lib -rzendebug comparison.rb $N)
fi

if [ $type = "debug-rex" ]; then
    (cd rexml_3.1.1/benchmarks/; yes c | ruby -I../../$RI -rdebug comparison.rb $N)
fi

if [ $type = "bench-rex" ]; then
    for type in native-rex zendebug-rex debug-rex; do
	echo "$type:"
	./zendebug-demo.sh $type $N
	echo
    done
fi
